describe("Flyby test suite", function() {

  var TestResource,
      requests = function() { return jasmine.Ajax.requests; };

  function each(items, fn) {
    for(var i = 0; i < items.length; i++) {
      fn(items[i]);
    }
  }

  function jsonString(x) {
    return JSON.stringify(x);
  }

  requests.latest = function() {
    return requests().mostRecent();
  };

  requests.latest.body = function() {
    return requests.latest().params;
  };

  requests.latest.body.json = function() {
    return JSON.parse(requests.latest.body());
  };

  beforeEach(function() {
    jasmine.Ajax.install();
  });

  afterEach(function() {
    jasmine.Ajax.uninstall();
  });

  describe("helpers test", function() {

    describe("paramRgx", function() {

      describe("when built with \"foobar\"", function() {

        it("should return a regular expression that will test FALSE for /something/:id/else", function() {
          var rgx = Flyby.fn.paramRgx("foobar");
          expect(rgx.test("/something/:id/else")).toBe(false);
        });

      });

      describe("when build with \"id\"", function() {

        it("should return a regular expression that will test TRUE for /something/:id/else", function() {
          var rgx = Flyby.fn.paramRgx("id");
          expect(rgx.test("/something/:id/else")).toBe(true)
        });

      });

    });

    describe("lookupDotted", function() {

      describe("when looking up paths against {foo: {bar: 1337}}", function() {

        var ctx;

        beforeEach(function() {
          ctx = {foo: {bar: 1337}};
        });

        it("looking up foo.bar should return 1337", function() {
          var result = Flyby.fn.lookupDotted(ctx, "foo.bar");
          expect(result).toBe(1337);
        });

        it("looking up user.name should return undefined", function() {
          var result = Flyby.fn.lookupDotted(ctx, "user.name");
          expect(result).toBeUndefined();
        });

      });

    });

    describe("extractObjectMappings", function() {

      it("shoud extract ONLY those properties that have mappings", function() {
        var data = {name: "danny", id: 1},
            mapping = {id: "@id"},
            result = Flyby.fn.extractObjectMappings(data, mapping);

        expect(result.id).toBe(1);
        expect(result.name).toBeUndefined();
      });

    });

    describe("transformUrl", function() {

      describe("when transforming /some/route/:id/with/:options", function() {

        var template,
            mapping;

        beforeEach(function() {
          template = "/some/route/:id/with/:options";
          mapping = {id: "@id", options: "@options"};
        });

        it("should options when given {options: 1}", function() {
          var result = Flyby.fn.transformUrl(template, {options: "goodies"}, mapping);
          expect(result).toBe("/some/route/with/goodies");
        });

        it("should populate id when given {id: 1}", function() {
          var result = Flyby.fn.transformUrl(template, {id: 1}, mapping);
          expect(result).toBe("/some/route/1/with");
        });

        it("should populate both when given {id: 1, options: foobar}", function() {
          var result = Flyby.fn.transformUrl(template, {id: 1, options: "foobar"}, mapping);
          expect(result).toBe("/some/route/1/with/foobar");
        });

      });

    });

    describe("omit", function() {

      each([{
        input: {
          obj: {name: "danny", age: 24},
          keys: ["name"]
        },
        result: {age: 24}
      }, {
        input: {
          obj: undefined,
          keys: ["name"],
        },
        result: undefined
      }], function(spec_config) {

        describe("when omitting "+jsonString(spec_config.input.keys)+" from "+jsonString(spec_config.input.obj), function() {

          it("should return "+jsonString(spec_config.result), function() {
            var r = Flyby.fn.omit(spec_config.input.obj, spec_config.input.keys);
            expect(r).toEqual(spec_config.result);
          });

        });

      });

    });

    describe("extend", function() {

      it("should copy all properties to the object", function() {
        var a = {};
        Flyby.fn.extend(a, {name: "danny"});
        expect(a.name).toBe("danny");
      });

      it("should support multiple sources", function() {
        var a = {};
        Flyby.fn.extend(a, {name: "danny"}, {age: 24});
        expect(a.name).toBe("danny");
        expect(a.age).toBe(24);
      });

    });

    describe("encodeUriQuery", function() {

      each([{
        input: "nothing-special",
        output: "nothing-special"
      }, {
        input: "[1,2,3]",
        output: "%5B1,2,3%5D"
      }, {
        input: "/something:123",
        output: "%2Fsomething:123"
      }, {
        input: "@dadleyy",
        output: "@dadleyy"
      }], function(test_config) {

        describe("when given "+test_config.input, function() {

          it("should return "+test_config.output, function() {
            var r =  Flyby.fn.encodeUriQuery(test_config.input);
            expect(r).toBe(test_config.output);
          });

        });

      });

    });

  });

  describe("headers function test suite", function() {

    var Resource = null;
    var called   = null;
    var headers  = null;

    beforeEach(function() {
      called  = false;
      headers = {};

      function getHeaders() {
        called = true;
        return headers;
      }

      Resource = Flyby("/api/custom-headers/:id", null, {
        make: {
          method: "GET",
          headers: getHeaders
        }
      });
    });

    it("should use the headers function if defined on custom actions", function() {
      expect(called).toBe(false);
      headers.foo = "bar";
      Resource.make({id: 10});
      var requestHeaders = requests.latest().requestHeaders;
      expect(called).toBe(true);
      expect(requestHeaders).toEqual({foo: "bar"});
    });

    it("should use the headers function if defined on custom actions", function() {
      expect(called).toBe(false);
      headers["Caps-Foo"] = "bar";
      Resource.make({id: 10});
      var requestHeaders = requests.latest().requestHeaders;
      expect(called).toBe(true);
      expect(requestHeaders).toEqual({"caps-foo": "bar"});
    });

    it("should use the headers function if defined on custom actions (called conecutively)", function() {
      expect(called).toBe(false);
      headers = {"Caps-Foo": "bar"};
      Resource.make({id: 10});
      var requestHeaders = requests.latest().requestHeaders;
      expect(called).toBe(true);
      expect(requestHeaders).toEqual({"caps-foo": "bar"});

      headers = {"Caps-Two": "bar"};

      Resource.make({id: 10});
      var requestHeaders = requests.latest().requestHeaders;
      expect(called).toBe(true);
      expect(requestHeaders).toEqual({"caps-two": "bar"});
    });

  });

  describe("basic resource definition", function() {

    beforeEach(function() {
      var actions = {},
          mappings = {};

      actions.strange = {
        method: "GET",
        has_body: false,
        headers: {
          "x-strange-header": "yes"
        }
      };

      actions.stranger = {
        method: "GET",
        has_body: false,
        headers: {
          "x-strange-header": function(data) {
            return data.id;
          }
        }
      };

      actions.variableMethod = {
        method: function(data) {
          return data.id ? "PUT" : "POST";
        }
      };

      actions.custom = {
        method: "POST",
        has_body: true,
        transform: {
          request: function(data) {
            return JSON.stringify(Object.keys(data));
          },
          response: function(response_text) {
            return "hello world";
          }
        }
      };

      mappings["id"] = "@id";
      mappings["options"] = ["@opt_a", "@opt_b"];

      TestResource = Flyby("/api/items/:id/:options", mappings, actions);
    });

    describe("when using a custom action that has provided a callback for the method", function() {

      it("should send PATCH based on the body", function() {
        TestResource.variableMethod({id: 222});
        expect(requests.latest().method).toBe("PUT");
      });

      it("should send POST based on the body", function() {
        TestResource.variableMethod({id: null});
        expect(requests.latest().method).toBe("POST");
      });

    });

    describe("using a url parameter with an array for the mapping", function() {

      it("should use the first key found", function() {
        TestResource.get({opt_a: "huzzah"});
        expect(requests.latest().url).toBe("/api/items/huzzah");
      });

      it("should fallback to the second key if the first is not provided", function() {
        TestResource.get({opt_b: "yea"});
        expect(requests.latest().url).toBe("/api/items/yea");
      });

    });

    describe("getting resource with .get", function() {

      it("should make a GET request to /api/items/1", function() {
        TestResource.get({id: 1});
        expect(requests.latest().method).toBe("GET");
        expect(requests.latest().url).toBe("/api/items/1");
      });


      it("should add additional params as query string params", function() {
        TestResource.get({user: 1});
        expect(requests.latest().method).toBe("GET");
        expect(requests.latest().url).toBe("/api/items?user=1");
      });

    });

    describe("creating resource with .create", function() {

      it("should make a POST request to /api/items", function() {
        TestResource.create({
          vendor: 1,
          amount: "100.00"
        });
        var body = requests.latest.body.json();
        expect(requests.latest().method).toBe("POST");
        expect(requests.latest().url).toBe("/api/items");
        expect(body.vendor).toBe(1);
        expect(body.amount).toBe("100.00");
        expect(typeof requests.latest.body()).toBe("string");
      });

    });

    describe("updating a resource with .update", function() {

      it("should send a PATH request to /api/items/1", function() {
        TestResource.update({
          id: 22,
          amount: "200.00"
        });
        var body = requests.latest.body.json();
        expect(requests.latest().method).toBe("PATCH");
        expect(requests.latest().url).toBe("/api/items/22");
        expect(body.amount).toBe("200.00");
      });

    });

    describe("deleting a resource with .destroy", function() {

      it("should send a DELETE request to /api/items/1", function() {
        TestResource.destroy({id: 22});
        expect(requests.latest().method).toBe("DESTROY");
        expect(requests.latest().url).toBe("/api/items/22");
      });

    });

    describe("using custom http headers", function() {

      it("should use the headers configured by the action", function() {
        TestResource.strange({id: 1});
        expect(requests.latest().requestHeaders["x-strange-header"]).toBe("yes");
      });

      it("should support actions using functions for their headers", function() {
        TestResource.stranger({id: "whoa"});
        expect(requests.latest().requestHeaders["x-strange-header"]).toBe("whoa");
      });

    });


    describe("response handling", function() {

      var a1, a2, a3;

      function callback(err, result, xhr) {
        a1 = err;
        a2 = result;
        a3 = xhr;
      }

      beforeEach(function() {
        a1 = null;
        a2 = null;
        a3 = null;
        TestResource.get({id: 1}, callback);
      });

      it("should return an error arg when response fails", function() {
        requests.latest().respondWith({
          status: 422,
          responseText: JSON.stringify({
            message: "failed"
          })
        });
        expect(a2).toBe(undefined);
      });

      it("should return json parsed data when server returns json", function() {
        requests.latest().respondWith({
          status: 200,
          responseHeaders: {
            "Content-Type": "application/json",
            "X-Other": "some other"
          },
          responseText: JSON.stringify({
            message: "major success"
          })
        });
        expect(a1).toBe(false);
        expect(typeof a2).toBe("object");
        expect(a2.message).toBe("major success");
        expect(a3.status).toBe(200);
      });

    });

    describe("custom actions", function() {

      var a1, a2, a3;

      function callback(err, result, xhr) {
        a1 = err;
        a2 = result;
        a3 = xhr;
      }

      beforeEach(function() {
        a1 = null;
        a2 = null;
        a3 = null;
      });

      it("should use the custom action's http verb", function() {
        TestResource.custom({something: "else"});
        expect(requests.latest().method).toBe("POST");
      });

      it("should use the request transformation function if present", function() {
        TestResource.custom({something: "else"}, callback);
        expect(requests.latest.body()).toEqual("[\"something\"]");
      });

      it("should use the response transform if present", function() {
        TestResource.custom({something: "else"}, callback);
        requests.latest().respondWith({
          status: 200,
          responseText: JSON.stringify({
          })
        });
        expect(a2).toBe("hello world");
      });

    });

  });

});
