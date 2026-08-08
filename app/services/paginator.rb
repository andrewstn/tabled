class Paginator
  DEFAULT_PER_PAGE = 25

  attr_reader :page, :per_page, :total_count, :records

  def initialize(relation, page:, per_page: DEFAULT_PER_PAGE)
    @relation = relation
    @per_page = per_page
    @total_count = relation.count
    @page = normalize_page(page)
    @records = paginated_records
  end

  def total_pages
    [ (total_count.to_f / per_page).ceil, 1 ].max
  end

  def previous_page
    page - 1 if page > 1
  end

  def next_page
    page + 1 if page < total_pages
  end

  def first_item
    total_count.zero? ? 0 : offset + 1
  end

  def last_item
    [ offset + per_page, total_count ].min
  end

  private

  def normalize_page(value)
    requested = value.to_i
    requested = 1 if requested < 1
    [ requested, total_pages ].min
  end

  def offset
    (page - 1) * per_page
  end

  def paginated_records
    return @relation.offset(offset).limit(per_page) if @relation.respond_to?(:offset)

    @relation.drop(offset).first(per_page)
  end
end
