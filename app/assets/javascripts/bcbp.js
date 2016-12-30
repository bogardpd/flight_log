$(function() {
  
  $('code.bcbp_raw').on('click', 'span', function(e) {
    var element = e.target;
    alert(element.getAttribute('data-index') + ": " + element.textContent);
  });
  
})