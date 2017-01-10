$(function() {
  
  var $rawText = jQuery('#bcbp_raw_text');
  // Check if there is a bcbp_raw_text element:
  if ($rawText.length > 0) {
    
    var $inputForm = jQuery('#bcbp_input_form');
    var $rawDataElements = jQuery('#bcbp_raw_text span');
    
    // Initialize Tooltip
    initTooltip();
  
    // Add input form functionality if the page has an input form
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
    
    function initTooltip() {
      // Create tooltip:
      var $tooltipDiv = jQuery('<div id="bcbp_tooltip" class="tooltip"></div>');
      $tooltipDiv.append('<div class="bcbp_description"></div>');
      $tooltipDiv.append('<div class="bcbp_raw_value"></div>');
      $tooltipDiv.append('<div class="bcbp_interpreted"></div>');
      $rawText.before($tooltipDiv)
      resetTooltip();
      
      // Add listeners:
      jQuery('code.bcbp_raw').on('click mouseenter', 'span', function(e) {
        var element = e.target;
        showTooltip(element);
      });
      jQuery('code.bcbp_raw').on('mouseleave', 'span', resetTooltip);
      
      // Change cursor for raw data code spans:
      $rawDataElements.css("cursor", "pointer");
    }
    
  
    function showTooltip(element) {
      var $element = jQuery(element);
      var $tooltip = jQuery('#bcbp_tooltip');
    
      // Highlight active element:
      $element.addClass('active');
      $element.siblings().removeClass('active');
    
      // Update description:  
      $tooltip.children('div').eq(0).text(element.getAttribute('data-description') + ":");
      
      // Update raw text:
      $tooltip.children('div').eq(1).empty(); // Clear all existing raw text
      // Add spans around each raw character and add to tooltip:
      element.textContent.split('').forEach(function(character) {
        var $span = jQuery('<span></span>');
        $span.text(character);
        $tooltip.children('div').eq(1).append($span);
      });
      
      // Update interpretation:
      $tooltip.children('div').eq(2).text(element.getAttribute('data-interpreted'));
      
    }
  
    function resetTooltip() {
      var $tooltip = jQuery('#bcbp_tooltip');
      $tooltip.children('div').eq(0).text("Hover over (or tap on) any part of the raw data to see details.");
      $tooltip.children('div').eq(1).empty();
      $tooltip.children('div').eq(2).empty();
      $rawDataElements.removeClass('active');
    }
  
  
    
    
  }
  
});