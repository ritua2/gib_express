$(function() {
  switch (window.location.pathname) {
    case '/terminal':
        $('#terminal-tab').addClass('active')
        break;
    case '/compile':
        $('#compile-tab').addClass('active')
        break;
    case '/run':
        $('#run-tab').addClass('active')
        break;
    case '/history':
        $('#history-tab').addClass('active')
        break;
    case '/help':
        $('#help-tab').addClass('active')
        break;
    case '/admin':
        $('#admin-tab').addClass('active')
        break;
    case '/community/blog/':
        $('#community-tab').addClass('active')
        break;
  }
});

// $('input').change(function(event){
//     $('#fullCommand').text($('#rcommand').val() + $('#binary').val() + ' ' + $('#rcommandargs').val());
// });
//
// $('input').change(function(event){
//     files =''
//     if ($('#addfiles').val()) {
//       var splitfiles = $('#addfiles').val().split(',')
//       for (i=0; i < splitfiles.length; i++) {
//         var filename = /[^/]*$/.exec(splitfiles[i].trim())[0] //grab the series of characters not containing a slash
//         files = files + ' ' + filename
//       }
//     }
//     $('#compileFullCommand').text($('#ccommand').val() + ' ' + $('#driver').val() + ' -o ' + $('#outfiles').val() + ' ' + $('#commargs').val() + ' ' + files);
// });
