$(function(){
  var ctx = document.getElementById("teacher-work-done-chart");
  var chartContainerElement = $("#chart-container");
  var noInfoChartElement = $("#no-info-chart");
  var flashMessages = new FlashMessages();

  $schoolCalendarStepElement = $('#school_calendar_step');
  $schoolCalendarStepElement.on('change', updateWorkDoneChart);

  function updateWorkDoneChart(){
    var schoolCalendarStepId = $('#school_calendar_step').val();
    if (!_.isEmpty(schoolCalendarStepId)) {
      $.ajax({
        url: Routes.dashboard_teacher_work_done_chart_index_pt_br_path(
          {
            format: 'json',
            school_calendar_step_id: schoolCalendarStepId
          }
        ),
        success: handleUpdateTeacherWOrkDoneChartSuccess,
        error: handleFetchTeacherWorkDoneChartError
      });
    }
  }

  function handleUpdateTeacherWOrkDoneChartSuccess(teacher_notes){
    if(teacher_notes.pending_notes_count == 0 && teacher_notes.completed_notes_count == 0){
      noInfoChartElement.show();
      $('#teacher-work-done-chart').hide();
      return;
    }
    noInfoChartElement.hide();
    $('#teacher-work-done-chart').show();
    teacherWorkDoneChart.data.datasets[0].data[0] = teacher_notes.completed_notes_count;
    teacherWorkDoneChart.data.datasets[0].data[1] = teacher_notes.pending_notes_count;
    teacherWorkDoneChart.update();
  }

  function mountWorkDoneChart(){
    var schoolCalendarStepId = $('#school_calendar_step').val();
    if (!_.isEmpty(schoolCalendarStepId)) {
      $.ajax({
        url: Routes.dashboard_teacher_work_done_chart_index_pt_br_path(
          {
            format: 'json',
            school_calendar_step_id: schoolCalendarStepId
          }
        ),
        success: handleFetchTeacherWorkDoneChartSuccess,
        error: handleFetchTeacherWorkDoneChartError
      });
    }
  }

  function handleFetchTeacherWorkDoneChartSuccess(teacher_notes) {
    if(teacher_notes.pending_notes_count == 0 && teacher_notes.completed_notes_count == 0){
      noInfoChartElement.show();
      $('#teacher-work-done-chart').hide();
      return;
    }
    noInfoChartElement.hide();
    $('#teacher-work-done-chart').show();
    var data = {
      labels: [
        "Notas lançadas",
        "Notas não lançadas"
      ],
      datasets: [
          {
            data: [teacher_notes.completed_notes_count, teacher_notes.pending_notes_count],
            backgroundColor: [
                "#36A2EB",
                "#FF6384"
            ],
            hoverBackgroundColor: [
                "#36A2EB",
                "#FF6384"
            ]
          }
        ]
      };
    teacherWorkDoneChart = new Chart(ctx,{
      type: 'doughnut',
      data: data,
      options: {
        animation:{
            animateScale:true
        },
        tooltips: {
          callbacks: {
            label: function(tooltipItem, data) {
              var dataset = data.datasets[tooltipItem.datasetIndex];

              var total = dataset.data.reduce(function(previousValue, currentValue, currentIndex, array) {
                return previousValue + currentValue;
              });

              var currentValue = dataset.data[tooltipItem.index];

              var percentage = Math.floor(((currentValue/total) * 100)+0.5);

              return " " + currentValue + " (" + percentage + "%)";
            }
          }
        }
      }
    });
  };

  function handleFetchTeacherWorkDoneChartError() {
    flashMessages.error('Ocorreu um erro ao gerar o gráfico.');
  };

  mountWorkDoneChart();
});
