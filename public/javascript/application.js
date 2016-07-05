// confirmation dialog
$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
  
    var ok = confirm("Ar you sure? This cannot be undone!");
    if (ok) {
      this.submit();
    }
  });

});
