module ExamPoster
  class TeacherScoresFetcher
    attr_reader :scores
    attr_reader :warning_messages

    def initialize(teacher, classroom, discipline, step)
      @teacher = teacher
      @classroom = classroom
      @discipline = discipline
      @step = step
      @warning_messages = []
      @scores = []
    end

    def fetch!
      exams = Avaliation.by_classroom_id(@classroom.id)
                        .by_discipline_id(@discipline.id)
                        .by_test_date_between(@step.start_at, @step.end_at)
      number_of_exams = exams.count

      daily_notes = DailyNote.by_classroom_id(@classroom.id)
                             .by_discipline_id(@discipline.id)
                             .by_test_date_between(@step.start_at, @step.end_at)
                             .active

      validate_exam_quantity(number_of_exams)
      validate_exam_quantity_for_fix_test(number_of_exams)
      validate_pending_exams(daily_notes, exams)

      students = fetch_student(daily_notes)

      daily_note_students = DailyNoteStudent.by_classroom_id(@classroom)
                                            .by_discipline_id(@discipline)
                                            .where(student: students)
                                            .by_test_date_between(@step.start_at, @step.end_at)
                                            .active

      @scores = daily_note_students.map do |dns|
        pending_exam = dns if dns.note.blank? && !dns.exempted?

        if pending_exam.present?
          pending_exam_string = pending_exam.daily_note.avaliation.description_to_teacher
          @warning_messages << "O aluno #{dns.student} não possui nota lançada no diário de avaliações numéricas na turma #{@classroom}, disciplina de #{@discipline}. Avaliação: #{pending_exam_string}."
        end

        dns.student
      end.uniq
    end

    def warnings?
      @warning_messages.present?
    end

    private

    def validate_exam_quantity(number_of_exams)
      return unless number_of_exams.zero?

      @warning_messages << "Não foi possível enviar as avaliações numéricas da turma #{@classroom} pois não foram cadastradas avaliações numéricas para a disciplina #{@discipline}."
    end

    def validate_exam_quantity_for_fix_test(number_of_exams)
      return unless current_test_setting.present? && current_test_setting.sum_calculation_type?
      return unless number_of_exams < current_test_setting.tests.count

      @warning_messages << "Não foi possível enviar as avaliações numéricas da turma #{@classroom} pois não foram cadastradas todas as avaliações numéricas da configuração de avaliações numéricas para a disciplina #{@discipline}."
    end

    def validate_pending_exams(daily_notes, exams)
      number_of_exams = exams.count
      if daily_notes.count < number_of_exams
        pending_exams = exams.select { |exam| daily_notes.none? { |daily_note| daily_note.avaliation_id == exam.id } }
        pending_exams_string = pending_exams.map(&:description_to_teacher).join(', ')
        @warning_messages << "Não foi possível enviar as avaliações numéricas da turma #{@classroom} pois existem avaliações que não foram lançadas no diário de avaliações numéricas para a disciplina #{@discipline}. Avaliações: #{pending_exams_string}."
      end
    end

    def fetch_student(daily_notes)
      student_enrollment_classrooms = daily_notes.map(&:avaliation).map do |avaliation|
        date_avaliation = avaliation.test_date

        StudentEnrollmentClassroom.includes(student_enrollment: :student)
                                  .by_classroom(@classroom.id)
                                  .by_date(date_avaliation)
                                  .active
      end
      student_enrollments = student_enrollment_classrooms.flatten.map(&:student_enrollment)
      student_enrollments.flatten.map(&:student).compact
    end

    def current_test_setting
      @current_test_setting ||= TestSettingFetcher.current(@classroom, @step)
    end
  end
end
