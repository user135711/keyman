var assert = chai.assert;

describe('KeymanWeb Initialization', function() {
  beforeEach(function(done) {
    fixture.setBase('unit_tests/fixtures');

    fixture.load("singleInput.html");
    setupKMW();

    setTimeout(function() {
      // Special Mocha trick - this forces Mocha to allow a page initialization time.
      done();
    }, 1000);
  });
  
  afterEach(function() {
    fixture.cleanup();
    teardownKMW();
  });
  
  describe('Initialization', function() {
    it('window.keyman should exist.', function() {
      assert.isNotNull(window.keyman, "KeymanWeb's base object doesn't exist!");
    });
    it('KMW should attach to the input element.', function() {
      var singleton = document.getElementById('singleton');
      assert.isTrue(keyman.isAttached(singleton), "KeymanWeb did not automatically attach to the element!");
    });
    it('KMW\'s initialization variable should indicate completion.', function() {
      assert(keyman.initialized == 2, 'Keyman indicates incomplete initialization!');
    });
  });
});

describe('Toggle UI Initialization', function() {

  beforeEach(function(done) {
    this.timeout(5000);
    fixture.setBase('unit_tests/fixtures');
    fixture.load('singleInput.html');

    setupKMW('toggle');

    setTimeout(function() {
      // Special Mocha trick - this forces Mocha to allow a page initialization time.
      done();
    }, 1500); // Set high to ensure KMW has time to fully initialize.  We do have a 1 sec delay in the initializer.
  });
  
  afterEach(function() {
    fixture.cleanup();
    teardownKMW();
  });

  it('The Toggle UI initializes correctly.', function() {
    assert(keyman.ui.initialized, 'Initialization flag is set to false!');
    
    assert.isNotNull(keyman.ui.controller, 'Failed to create the controller element!');

    var divs = document.getElementsByTagName("div");
    var match = false;

    for(var i=0; i < divs.length; i++) {
      if(divs[i] == keyman.ui.controller) {
        match = true;
      }
    }

    assert(match, 'Controller element has not been added to the page!');
  })
});

describe('Button UI Initialization', function() {

  beforeEach(function(done) {
    this.timeout(5000);
    fixture.setBase('unit_tests/fixtures');
    fixture.load('singleInput.html');

    setupKMW('button');

    setTimeout(function() {
      // Special Mocha trick - this forces Mocha to allow a page initialization time.
      done();
    }, 1500); // Set high to ensure KMW has time to fully initialize.  We do have a 1 sec delay in the initializer.
  });
  
  afterEach(function() {
    fixture.cleanup();
    teardownKMW();
  });

  it('The Button UI initializes correctly.', function() {
    assert(keyman.ui.init, 'Initialization flag is set to false!');
  })
});

describe('Float UI Initialization', function() {

  beforeEach(function(done) {
    this.timeout(5000);
    fixture.setBase('unit_tests/fixtures');
    fixture.load('singleInput.html');

    setupKMW('float');

    setTimeout(function() {
      // Special Mocha trick - this forces Mocha to allow a page initialization time.
      done();
    }, 1500); // Set high to ensure KMW has time to fully initialize.  We do have a 1 sec delay in the initializer.
  });
  
  afterEach(function() {
    fixture.cleanup();
    teardownKMW();
  });

  it('The Float UI initializes correctly.', function() {
    assert(keyman.ui.initialized, 'Initialization flag is set to false!');
    
    assert.isNotNull(keyman.ui.outerDiv, 'Failed to create the floating controller element!');

    var divs = document.getElementsByTagName("div");
    var match = false;

    for(var i=0; i < divs.length; i++) {
      if(divs[i] == keyman.ui.outerDiv) {
        match = true;
      }
    }

    assert(match, 'Floating controller element has not been added to the page!');
  })
});