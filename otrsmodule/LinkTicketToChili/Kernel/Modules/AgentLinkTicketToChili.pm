# --
# Kernel/Modules/AgentLinkTicketToChili.pm - frontend modul
# Copyright (C) 2012 Florian Pommerening (admin@praedisoft.de)
# --

package Kernel::Modules::AgentLinkTicketToChili;

use strict;
use warnings;

use Date::Pcalc qw(Add_Delta_YMD);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless ($Self, $Type);

    # check needed objects
    for (qw(ParamObject DBObject TicketObject LayoutObject UserObject
            LogObject QueueObject ConfigObject UserID TicketID)) {
        if ( !$Self->{$_} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
        }
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Data = {};

    # check permissions
    my $Access = $Self->{TicketObject}->TicketPermission(
        Type     => 'rw',
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID}
    );

    # error screen, don't show ticket
    if ( !$Access ) {
        if ( $Self->{Subaction} eq 'SetChiliTicketID' ) {
            # REST call: respond with header
            return $Self->headerOnly("403 Forbidden");
        }
        return $Self->{LayoutObject}->NoPermission( WithHeader => 'yes' );
    }

    # start with actions
    if ( $Self->{Subaction} eq 'SetChiliTicketID' ) {
        my $ChiliTicketID = $Self->{ParamObject}->GetParam( Param => 'ChiliTicketID' );
        my $TicketID = $Self->{ParamObject}->GetParam( Param => 'TicketID' );

        if (!$TicketID || !$ChiliTicketID) {
            return $Self->headerOnly("500 Internal Server Error");
        }

        my $DynamicFieldConfig = $Self->{TicketObject}->{DynamicFieldObject}->DynamicFieldGet(
            Name => "chiliticketid",
        );

        my $Success = $Self->{TicketObject}->{DynamicFieldBackendObject}->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $TicketID,
            Value              => $ChiliTicketID,
            UserID             => $Self->{UserID},
        );

        my $Success = $Success && $Self->{TicketObject}->TicketStateSet(
            State    => "In Bearbeitung",
            TicketID => $TicketID,
            UserID   => $Self->{UserID},
        );

        my ( $Sec, $Min, $Hour, $Day, $Month, $Year ) = $Self->{TimeObject}->SystemTime2Date(
            SystemTime => $Self->{TimeObject}->SystemTime(),
        );
        my ( $YearPending, $MonthPending, $DayPending ) = Add_Delta_YMD( $Year, $Month, $Day, 0, 2, 0 );
        
        my $Success = $Success && $Self->{TicketObject}->TicketPendingTimeSet(
            Year     => $YearPending,
            Month    => $MonthPending,
            Day      => $DayPending,
            Hour     => 12,
            Minute   => 30,
            TicketID => $TicketID,
            UserID   => $Self->{UserID},
        );

        if (!$Success) {
            return $Self->headerOnly("500 Internal Server Error");
        }
        return $Self->headerOnly("200 OK");
    }
    else {
        $Data->{TicketID} = $Self->{TicketID};
        
        my %Ticket = $Self->{TicketObject}->TicketGet(
            TicketID => $Self->{TicketID},
            UserID => $Self->{UserID},
        );        
        $Data->{TicketTitle} = %Ticket->{Title};

        my %OpeningArticle = $Self->{TicketObject}->ArticleFirstArticle(
            TicketID => $Self->{TicketID},
            UserID => $Self->{UserID},
        );        
        $Data->{TicketBody} = %OpeningArticle->{Body};
        $Data->{TicketBody} =~ s{\n}{\\n}g;

        my %Preferences = $Self->{UserObject}->GetPreferences(
            UserID => $Self->{UserID},
        );
        $Data->{ChiliAPIKey} = %Preferences->{AgentAPIKey};

        # build output
        my $Output = $Self->{LayoutObject}->Header(Title => "Linking Ticket ".$Data->{TicketID}." to Chili");
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Output(
            Data => $Data,
            TemplateFile => 'AgentLinkTicketToChili',
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
}

# There should be a more straight-forward way to do this but I didn't find it
sub headerOnly() {
    my ( $Self, $Status ) = @_;
    return "Content-Type: text/html; charset=utf-8;\nStatus: " . $Status . "\nContent-Length: 0\n\n";
}

sub headerWithContent() {
    my ( $Self, $Status, $Content ) = @_;
    return "Content-Type: text/html; charset=utf-8;\nStatus: " . $Status . "\n\n" . $Content;
}

1;
