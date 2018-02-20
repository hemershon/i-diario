class AvaliationMultipleCreatorForm
  include ActiveModel::Model
  include I18n::Alchemy


  attr_accessor :test_setting_id, :unity_id, :discipline_id, :test_setting_test_id,
                :description, :weight, :observations, :school_calendar_id, :avaliations, :teacher_id

  validates :unity_id,             presence: true
  validates :discipline_id,        presence: true
  validates :school_calendar_id,   presence: true
  validates :test_setting_id,      presence: true
  validates :test_setting_test_id, presence: true, if: :sum_calculation_type?
  validates :description,       presence: true, if: -> { !sum_calculation_type? || allow_break_up? }
  validates :weight,            presence: true, if: :should_validate_weight?
  validate :at_least_one_assigned_avaliation

  def initialize(attributes = {})
    @avaliations = []
    super
  end

  def valid?
    super && add_avaliations_errors_to_classrooms
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      avaliations.select(&:include).each(&:save!)
      self
    end
  end

  def test_setting
    return if test_setting_id.blank?
    @test_setting ||= TestSetting.find(test_setting_id)
  end

  def unity
    return if unity_id.blank?
    @unity ||= Unity.find(unity_id)
  end

  def discipline
    return if discipline_id.blank?
    @discipline ||= Discipline.find(discipline_id)
  end

  def test_setting_test
    return if test_setting_test_id.blank?
    @test_setting_test ||= TestSettingTest.find(test_setting_test_id)
  end

  def school_calendar
    SchoolCalendar.find_by(id: school_calendar_id)
  end

  def avaliations_attributes=(value)
    return unless value.present?

    @avaliations = []
    value.each do |avaliation_attributes|
      avaliation = Avaliation.new.localized
      avaliation.assign_attributes(
        include: avaliation_attributes.last['include'] == "1",
        classroom_id: avaliation_attributes.last['classroom_id'],
        test_date: avaliation_attributes.last['test_date'],
        classes: avaliation_attributes.last['classes'],
        test_setting_id: self.test_setting_id,
        discipline_id: self.discipline_id,
        test_setting_test_id: self.test_setting_test_id,
        description: self.description,
        weight: self.weight,
        observations: self.observations,
        school_calendar_id: self.school_calendar_id
      )
      @avaliations << avaliation
    end
  end

  def load_avaliations!(teacher_id, school_calendar_year)
    return unless discipline_id.present? && teacher_id.present?
    classrooms = Classroom
      .by_unity_and_teacher(unity_id, teacher_id)
      .by_teacher_discipline(discipline_id)
      .by_year(school_calendar_year)
      .ordered

    @avaliations = []
    classrooms.each do |classroom|
      @avaliations << Avaliation.new(
        classroom_id: classroom.id
      )
    end
  end

  protected

  def at_least_one_assigned_avaliation
    errors.add(:avaliations, :at_least_one_assigned_avaliation) if avaliations.select(&:include).blank?
  end

  def allow_break_up?
    test_setting_test && test_setting_test.allow_break_up
  end

  def average_calculation_type
    return "" if test_setting.nil?
    test_setting.average_calculation_type
  end

  def sum_calculation_type?
    average_calculation_type == "sum"
  end

  def arithmetic_and_sum_calculation_type?
    average_calculation_type == "arithmetic_and_sum"
  end

  def should_validate_weight?
    allow_break_up? || arithmetic_and_sum_calculation_type?
  end

  def add_avaliations_errors_to_classrooms
    valid = true
    avaliations.select(&:include).each do |avaliation|
      if !avaliation.valid?
        msg = avaliation.errors.full_messages.reject{|msg| msg.include?("Data da avaliação") || msg.include?("Aulas")}.first
        errors.add(:base, msg) if msg
        avaliation.errors.add(:classroom, msg)
        valid = false
      end
    end
    valid
  end
end
