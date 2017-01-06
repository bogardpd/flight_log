$(function() {
  
  $('code.bcbp_raw').on('click', 'span', function(e) {
    var element = e.target;
    alert(element.getAttribute('data-description') + ": " + element.textContent);
  });
  
})