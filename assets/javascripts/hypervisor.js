var documentation = {};
var documentation_by_id = {};

//
String.prototype.escapeHTML = function () {
  return(                                                                 
    this.replace(/\&/g,'&amp;').                                
         replace(/\>/g,'&gt;').
         replace(/\</g,'&lt;').
         replace(/\"/g,'&quot;')
  );                                 
};

//
HyperVisor = {

  //
  bootup: function() {
    var urlVars = HyperVisor.getUrlVars();
    var url     = urlVars['doc'] || 'doc.json'

    $.getJSON(url, function(data) {
      // set up documentation & alphabetical table
      table = new Array();
      $.each(data, function(key, doc) {
        doc.key = key;  // ensure key is the same
        if (doc.path != undefined) {
          doc.id = HyperVisor.cleanId('api-' + doc['!'] + '-' + doc.path);
        } else {
          doc.id = 'metadata'
        }
        table.push(doc);
        // by key
        documentation[doc.key] = doc;
        // by id
        documentation_by_id[doc.id] = doc;
      });
      table.sort(HyperVisor.compareNames);

      documentation = data;  // global variable
      metadata      = data['(metadata)'];

      $('#header-title').append($('#template-header-title').jqote(metadata));
      $('#header-resources').append($('#template-header-resources').jqote(metadata));

      $.each(table, function(index, value) {
        type = value['!'];
        switch(type) {
        case 'method':
          $('#methods').append($('#template-method-link').jqote(value));
          break;
        case 'class':
          $('#classes').append($('#template-class-link').jqote(value));
          break;
        case 'module':
          $('#classes').append($('#template-module-link').jqote(value));
          break;
        case 'document':
        case 'file':
          $('#file').append($('#template-file-link').jqote(value));
          break;
        case 'script':
          $('#file').append($('#template-file-link').jqote(value));
          break;
        };
      });

      if(metadata.copyrights != null){
        $.each(metadata.copyrights, function(i, cr) {
          $('#copyrights').append($('#template-copyright').jqote(cr));
        });
      }

      // TODO: how to generalize? also add '/' prefix in future.
      //toggleBox('#api-README-dot-rdoc', 'README.rdoc');
      // $('#infobox').append($('#template-file-info').jqote(documentation['README.rdoc']));
      // $('#api-README-dot-rdoc').show();

      //$(".scroll").scrollable({mousewheel: true}).navigator();

      $('input#search-input').quicksearch('.items li');

      $('input#search-letter').quicksearch('.items li', {
        'prepareQuery': function (val) {
          return new RegExp('^'+val, 'i');
        },
        'testQuery': function (query, txt, _row) {
          return query.test(txt);
        },
        'bind': 'keyup'
      });

      // CENTRAL CONTROL
      $.history.init(function(hash){
        if(hash == "") {          // TODO: use main setting
          HyperVisor.toggleBox('api-document-README.rdoc');
        } else {
          HyperVisor.toggleBox(hash);   // restore the state from hash
        }
      });

    });

    $(".scroll").mouseover(function(event) {
      var ul  = $(this).find('ul');
      var li  = ul.find('li:visible');
      var sum = 0;
      li.each( function(){ sum += $(this).outerWidth(); });
      ul.width(sum);
    });

    $(".scroll").mousewheel(function(event, delta) {
      this.scrollLeft -= (delta * event.pageX);
      event.preventDefault();
    });

    // Build ABC filter bar.
    $('#abctabs').append($('#template-abctabs').jqote());
    var letters = '';
    for(i=65;i<91;i++){
      letters = letters + ',' + String.fromCharCode(i);
    };
    letters = letters + ',backspace'
    key(letters, function(event, handler){
      var s = handler.shortcut;
      if(s == 'backspace'){s = ' '};
      $("input#search-letter").val(s).trigger('keyup');
      $('#clear-button').focus();
    });

  },

  cleanId: function(anId) {
    // anId = encodeURIComponent(anId);  DID NOT WORK
    anId = anId.replace(/\</g,  "-l-");
    anId = anId.replace(/\>/g,  "-g-");
    anId = anId.replace(/\=/g,  "-e-");
    anId = anId.replace(/\?/g,  "-q-");
    anId = anId.replace(/\!/g,  "-x-");
    anId = anId.replace(/\~/g,  "-t-");
    anId = anId.replace(/\[/g,  "-b-");
    anId = anId.replace(/\]/g,  "-k-");
    anId = anId.replace(/\#/g,  "-h-");
    anId = anId.replace(/\./g,  "-d-");
    anId = anId.replace(/\:\:/g,"-C-");
    anId = anId.replace(/\:/g,  "-c-");
    anId = anId.replace(/[/]/g, "-s-");
    anId = anId.replace(/\W+/g, "-");  // TOO GENERAL?
    anId = anId.replace(/\W+/g, "-");  // For GOOD MEASURE
    return(anId);
  },

  toggleBox: function(boxId) {
    var id = this.cleanId(boxId);
    //console.log(id);
    //if ($(boxId).length == 0) {
      data = documentation_by_id[id];
      //console.log(data);
      $('#infobox').append($('#template-' + data['!'] + '-info').jqote(data));
      $('.box').hide();
      $('#'+id).toggle();
      $('#'+id).find('pre code').each(function(i, e){hljs.highlightBlock(e, '  ')});
    //} else {
    //  $('.box').hide();
    //  $(boxId).toggle();
    //}
  },

  toggleBoxByKey: function(key) {
    boxId = this.cleanId(key);
    //if ($(boxId).length == 0) {
      data = documentation[key];
      $('#infobox').append($('#template-' + data['!'] + '-info').jqote(data));
      //boxId = boxId.replace(/[.,?!\s]/g, "_"); 
      $('.box').hide();
      $(boxId).toggle();
      $(boxId).find('pre code').each(function(i, e){hljs.highlightBlock(e, '  ')});
    //} else {
    //  $('.box').hide();
    //  $(boxId).toggle();
    //}
  },

  //
  compareNames: function(a, b){
    if (a.name < b.name) {return -1}
    if (a.name > b.name) {return 1}
    return 0;
  },

  //
  viewMetaRecursive: function(data) {
    var html = '<ul>';
    for (var k in data) {
      if (data[k] instanceof Object) {
        html = html + '<li>' + k + ' ' + HyperVisor.viewMetaRecursive(data[k]);
      } else {
        html = html + '<li>' + k + ' <code>' + ('' + data[k]).escapeHTML() + '</code>';
      }
      html = html + '</li>';
    }
    html = html + '</ul>';
    return html;
  },

  //
  viewMeta: function(){
    $.getJSON('doc.json', function(data) {
      $('.box').hide();
      $('#raw').show();
      $('#raw').append(HyperVisor.viewMetaRecursive(data));
    });
  },

  //
  clickABCTab: function(letter) {
    $("input#search-letter").val(letter).trigger('keyup');
  },

  //
  getUrlVars: function() {
    var vars = [], hash;
    var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    for(var i = 0; i < hashes.length; i++)
    {
      hash = hashes[i].split('=');
      vars.push(hash[0]);
      vars[hash[0]] = hash[1];
    }
    return vars;
  },

};



/*
function sortObj(arr){
  // Setup Arrays
  var sortedKeys = new Array();
  var sortedObj = {};
  // Separate keys and sort them
  for (var i in arr){
    sortedKeys.push(i);
  }
  sortedKeys.sort();
  // Reconstruct sorted obj based on keys
  for (var i in sortedKeys){
    sortedObj[sortedKeys[i]] = arr[sortedKeys[i]];
  }
  return sortedObj;
};
*/

