$(function() {
  
  $inputForm = jQuery('#bcbp_input_form');
  $rawText = jQuery('#bcbp_raw_text');
  
  if ($inputForm.length > 0) {
    // This page has an input form, so hide it and create a button to show it
    
    $rawText.append('<p><button id="show_bcbp_input_form">Edit Boarding Pass Text</button></p>');
    $editButton = jQuery('#show_bcbp_input_form');
    $inputForm = $inputForm.detach();
    
    $editButton.on('click', function() {
      $rawText.after($inputForm).hide();
      jQuery('#bcbp_submit_button').after(' <button id="bcbp_cancel_button">Cancel</button>');
      $cancelButton = jQuery('#bcbp_cancel_button');
      $cancelButton.on('click', function() {
        $inputForm.hide();
        $rawText.show();
      });
    });
  }
  
  
  
  jQuery('code.bcbp_raw').on('click', 'span', function(e) {
    var element = e.target;
    alert(element.getAttribute('data-description') + ": " + element.textContent);
  });
  
})