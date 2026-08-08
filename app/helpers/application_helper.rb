module ApplicationHelper
  def current_semester_label(date = Date.current)
    term = case date.month
    when 1..4 then "Spring"
    when 5..7 then "Summer"
    else "Fall"
    end

    "#{term} #{date.year}"
  end

  def pagination_url(page, anchor: nil)
    url_options = request.path_parameters.merge(request.query_parameters).merge(page: page)
    url_options[:anchor] = anchor if anchor.present?
    url_for(url_options)
  end
end
