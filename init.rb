require 'redmine'

require_dependency 'otrs2_chili_hooks'

Redmine::Plugin.register :chiliproject_otrs2_chili do
  name 'Otrs2Chili plugin'
  author 'Florian Pommerening'
  description 'Allows to create a ticket with a given OTRS ticket id and given body from OTRS'
  version '0.0.1'
  url 'https://github.com/EugenMayer/chiliproject_otrs2_chili'
  settings :partial => 'settings/otrs2_chili_settings',
    :default => {
        'otrs_ticket_base_link' => 'https://your.otrs.server/otrs/index.pl?Action=AgentTicketZoom;TicketID=<id>',
        'cors_allowed_origin' => 'https://your.chili.server',
        'otrs_links_custom_field' => 'OTRS Tickets',
        'ticket_type_custom_field' => 'Type',
        'ticket_type_value' => 'Kundenticket',
        'stop_words' => "aber,als,am,an,auch,auf,aus,bei,bin,bis,ist,da,dadurch,daher,darum,das,daß,dass,dein,deine,dem,den,der,des,dessen,deshalb,die,dies,dieser,dieses,doch,dort,du,durch,ein,eine,einem,einen,einer,eines,er,es,euer,eure,für,hatte,hatten,hattest,hattet,hier,hinter,ich,ihr,ihre,im,in,ist,ja,jede,jedem,jeden,jeder,jedes,jener,jenes,jetzt,kann,kannst,können,könnt,machen,mein,meine,mit,muß,mußt,musst,müssen,müßt,nach,nachdem,nein,ncht,nun,oder,seid,sein,seine,sich,sie,sind,soll,sollen,sollst,sollt,sonst,soweit,sowie,und,unser,unsere,unter,vom,von,vor,wann,warum,was,weiter,weitere,wenn,wer,werde,werden,werdet,weshalb,wie,wieder,wieso,wir,wird,wirst,wo,woher,wohin,zu,zum,zur,über",
        'number_of_returned_results' => '20',
      }
end

class OtrsUrlsCustomFieldFormat < Redmine::CustomFieldFormat
  include ActionView::Helpers::TagHelper

  def format_as_otrs_urls(value)
    base_link = Setting.plugin_chiliproject_otrs2_chili['otrs_ticket_base_link']
    otrs_ids = value.split(",")
    otrs_links = otrs_ids.map do |id|
      id = h(id.strip)
      if id =~ /^\d+$/
        '<a href="' + h(base_link.gsub("<id>", id)) + '">' + id + '</a>'
      else
        id
      end
    end
    ActiveSupport::SafeBuffer.new(otrs_links.join(", "))
  end

  def escape_html?
    false
  end

  def edit_as
   "string"
  end
end

Redmine::CustomFieldFormat.map do |fields|
  fields.register OtrsUrlsCustomFieldFormat.new('otrs_urls', :label => :label_otrs_urls, :order => 8)
end