class StudentEnrollmentsRetriever

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @search_type = params.fetch(:search_type, :by_date)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @date = params.fetch(:date, nil)

    ensure_has_valid_params
  end

  def call
    return if @classroom.blank? || @discipline.blank? || @search_type.blank?

    students_enrollments ||= StudentEnrollment.by_classroom(@classroom)
                                              .by_discipline(@discipline)
                                              .by_score_type(@score_type, @classroom)
                                              .joins(:student)
                                              .includes(:student)
                                              .includes(:dependences)
                                              .includes(:student_enrollment_classrooms)
                                              .active
  end

  private
  def ensure_has_valid_params
    if @search_type.eql?(:by_date)
      raise ArgumentError, 'Should define date argument on search by date' unless @date
    # elsif search_type.eql?(:by_date_range)
    #   raise ArgumentError, 'Should define start_at and end_at arguments on search by date range' unless start_at || end_at
    # elsif search_type.eql?(:by_year)
    #   raise ArgumentError, 'Should define start_at and end_at arguments on search by date range' unless start_at || end_at
    end
  end

  # def outros
  #
  # end

end