/*
Unobtrusive JavaScript
https://github.com/rails/rails/blob/main/actionview/app/javascript
Released under the MIT license
 */
(function(global, factory) {
  typeof exports === "object" && typeof module !== "undefined" ? module.exports = factory() : typeof define === "function" && define.amd ? define(factory) : (global = typeof globalThis !== "undefined" ? globalThis : global || self, 
  global.Rails = factory());
})(this, (function() {
  "use strict";
  const linkClickSelector = "a[data-confirm], a[data-method], a[data-remote]:not([disabled]), a[data-disable-with], a[data-disable]";
  const buttonClickSelector = {
    selector: "button[data-remote]:not([form]), button[data-confirm]:not([form])",
    exclude: "form button"
  };
  const inputChangeSelector = "select[data-remote], input[data-remote], textarea[data-remote]";
  const formSubmitSelector = "form:not([data-turbo=true])";
  const formInputClickSelector = "form:not([data-turbo=true]) input[type=submit], form:not([data-turbo=true]) input[type=image], form:not([data-turbo=true]) button[type=submit], form:not([data-turbo=true]) button:not([type]), input[type=submit][form], input[type=image][form], button[type=submit][form], button[form]:not([type])";
  const formDisableSelector = "input[data-disable-with]:enabled, button[data-disable-with]:enabled, textarea[data-disable-with]:enabled, input[data-disable]:enabled, button[data-disable]:enabled, textarea[data-disable]:enabled";
  const formEnableSelector = "input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled, input[data-disable]:disabled, button[data-disable]:disabled, textarea[data-disable]:disabled";
  const fileInputSelector = "input[name][type=file]:not([disabled])";
  const linkDisableSelector = "a[data-disable-with], a[data-disable]";
  const buttonDisableSelector = "button[data-remote][data-disable-with], button[data-remote][data-disable]";
  let nonce = null;
  const loadCSPNonce = () => {
    const metaTag = document.querySelector("meta[name=csp-nonce]");
    return nonce = metaTag && metaTag.content;
  };
  const cspNonce = () => nonce || loadCSPNonce();
  const m = Element.prototype.matches || Element.prototype.matchesSelector || Element.prototype.mozMatchesSelector || Element.prototype.msMatchesSelector || Element.prototype.oMatchesSelector || Element.prototype.webkitMatchesSelector;
  const matches = function(element, selector) {
    if (selector.exclude) {
      return m.call(element, selector.selector) && !m.call(element, selector.exclude);
    } else {
      return m.call(element, selector);
    }
  };
  const EXPANDO = "_ujsData";
  const getData = (element, key) => element[EXPANDO] ? element[EXPANDO][key] : undefined;
  const setData = function(element, key, value) {
    if (!element[EXPANDO]) {
      element[EXPANDO] = {};
    }
    return element[EXPANDO][key] = value;
  };
  const $ = selector => Array.prototype.slice.call(document.querySelectorAll(selector));
  const isContentEditable = function(element) {
    var isEditable = false;
    do {
      if (element.isContentEditable) {
        isEditable = true;
        break;
      }
      element = element.parentElement;
    } while (element);
    return isEditable;
  };
  const csrfToken = () => {
    const meta = document.querySelector("meta[name=csrf-token]");
    return meta && meta.content;
  };
  const csrfParam = () => {
    const meta = document.querySelector("meta[name=csrf-param]");
    return meta && meta.content;
  };
  const CSRFProtection = xhr => {
    const token = csrfToken();
    if (token) {
      return xhr.setRequestHeader("X-CSRF-Token", token);
    }
  };
  const refreshCSRFTokens = () => {
    const token = csrfToken();
    const param = csrfParam();
    if (token && param) {
      return $('form input[name="' + param + '"]').forEach((input => input.value = token));
    }
  };
  const AcceptHeaders = {
    "*": "*/*",
    text: "text/plain",
    html: "text/html",
    xml: "application/xml, text/xml",
    json: "application/json, text/javascript",
    script: "text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"
  };
  const ajax = options => {
    options = prepareOptions(options);
    var xhr = createXHR(options, (function() {
      const response = processResponse(xhr.response != null ? xhr.response : xhr.responseText, xhr.getResponseHeader("Content-Type"));
      if (Math.floor(xhr.status / 100) === 2) {
        if (typeof options.success === "function") {
          options.success(response, xhr.statusText, xhr);
        }
      } else {
        if (typeof options.error === "function") {
          options.error(response, xhr.statusText, xhr);
        }
      }
      return typeof options.complete === "function" ? options.complete(xhr, xhr.statusText) : undefined;
    }));
    if (options.beforeSend && !options.beforeSend(xhr, options)) {
      return false;
    }
    if (xhr.readyState === XMLHttpRequest.OPENED) {
      return xhr.send(options.data);
    }
  };
  var prepareOptions = function(options) {
    options.url = options.url || location.href;
    options.type = options.type.toUpperCase();
    if (options.type === "GET" && options.data) {
      if (options.url.indexOf("?") < 0) {
        options.url += "?" + options.data;
      } else {
        options.url += "&" + options.data;
      }
    }
    if (!(options.dataType in AcceptHeaders)) {
      options.dataType = "*";
    }
    options.accept = AcceptHeaders[options.dataType];
    if (options.dataType !== "*") {
      options.accept += ", */*; q=0.01";
    }
    return options;
  };
  var createXHR = function(options, done) {
    const xhr = new XMLHttpRequest;
    xhr.open(options.type, options.url, true);
    xhr.setRequestHeader("Accept", options.accept);
    if (typeof options.data === "string") {
      xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
    }
    if (!options.crossDomain) {
      xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
      CSRFProtection(xhr);
    }
    xhr.withCredentials = !!options.withCredentials;
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        return done(xhr);
      }
    };
    return xhr;
  };
  var processResponse = function(response, type) {
    if (typeof response === "string" && typeof type === "string") {
      if (type.match(/\bjson\b/)) {
        try {
          response = JSON.parse(response);
        } catch (error) {}
      } else if (type.match(/\b(?:java|ecma)script\b/)) {
        const script = document.createElement("script");
        script.setAttribute("nonce", cspNonce());
        script.text = response;
        document.head.appendChild(script).parentNode.removeChild(script);
      } else if (type.match(/\b(xml|html|svg)\b/)) {
        const parser = new DOMParser;
        type = type.replace(/;.+/, "");
        try {
          response = parser.parseFromString(response, type);
        } catch (error1) {}
      }
    }
    return response;
  };
  const href = element => element.href;
  const isCrossDomain = function(url) {
    const originAnchor = document.createElement("a");
    originAnchor.href = location.href;
    const urlAnchor = document.createElement("a");
    try {
      urlAnchor.href = url;
      return !((!urlAnchor.protocol || urlAnchor.protocol === ":") && !urlAnchor.host || originAnchor.protocol + "//" + originAnchor.host === urlAnchor.protocol + "//" + urlAnchor.host);
    } catch (e) {
      return true;
    }
  };
  let preventDefault;
  let {CustomEvent: CustomEvent} = window;
  if (typeof CustomEvent !== "function") {
    CustomEvent = function(event, params) {
      const evt = document.createEvent("CustomEvent");
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
      return evt;
    };
    CustomEvent.prototype = window.Event.prototype;
    ({preventDefault: preventDefault} = CustomEvent.prototype);
    CustomEvent.prototype.preventDefault = function() {
      const result = preventDefault.call(this);
      if (this.cancelable && !this.defaultPrevented) {
        Object.defineProperty(this, "defaultPrevented", {
          get() {
            return true;
          }
        });
      }
      return result;
    };
  }
  const fire = (obj, name, data) => {
    const event = new CustomEvent(name, {
      bubbles: true,
      cancelable: true,
      detail: data
    });
    obj.dispatchEvent(event);
    return !event.defaultPrevented;
  };
  const stopEverything = e => {
    fire(e.target, "ujs:everythingStopped");
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
  };
  const delegate = (element, selector, eventType, handler) => element.addEventListener(eventType, (function(e) {
    let {target: target} = e;
    while (!!(target instanceof Element) && !matches(target, selector)) {
      target = target.parentNode;
    }
    if (target instanceof Element && handler.call(target, e) === false) {
      e.preventDefault();
      e.stopPropagation();
    }
  }));
  const toArray = e => Array.prototype.slice.call(e);
  const serializeElement = (element, additionalParam) => {
    let inputs = [ element ];
    if (matches(element, "form")) {
      inputs = toArray(element.elements);
    }
    const params = [];
    inputs.forEach((function(input) {
      if (!input.name || input.disabled) {
        return;
      }
      if (matches(input, "fieldset[disabled] *")) {
        return;
      }
      if (matches(input, "select")) {
        toArray(input.options).forEach((function(option) {
          if (option.selected) {
            params.push({
              name: input.name,
              value: option.value
            });
          }
        }));
      } else if (input.checked || [ "radio", "checkbox", "submit" ].indexOf(input.type) === -1) {
        params.push({
          name: input.name,
          value: input.value
        });
      }
    }));
    if (additionalParam) {
      params.push(additionalParam);
    }
    return params.map((function(param) {
      if (param.name) {
        return `${encodeURIComponent(param.name)}=${encodeURIComponent(param.value)}`;
      } else {
        return param;
      }
    })).join("&");
  };
  const formElements = (form, selector) => {
    if (matches(form, "form")) {
      return toArray(form.elements).filter((el => matches(el, selector)));
    } else {
      return toArray(form.querySelectorAll(selector));
    }
  };
  const handleConfirmWithRails = rails => function(e) {
    if (!allowAction(this, rails)) {
      stopEverything(e);
    }
  };
  const confirm = (message, element) => window.confirm(message);
  var allowAction = function(element, rails) {
    let callback;
    const message = element.getAttribute("data-confirm");
    if (!message) {
      return true;
    }
    let answer = false;
    if (fire(element, "confirm")) {
      try {
        answer = rails.confirm(message, element);
      } catch (error) {}
      callback = fire(element, "confirm:complete", [ answer ]);
    }
    return answer && callback;
  };
  const handleDisabledElement = function(e) {
    const element = this;
    if (element.disabled) {
      stopEverything(e);
    }
  };
  const enableElement = e => {
    let element;
    if (e instanceof Event) {
      if (isXhrRedirect(e)) {
        return;
      }
      element = e.target;
    } else {
      element = e;
    }
    if (isContentEditable(element)) {
      return;
    }
    if (matches(element, linkDisableSelector)) {
      return enableLinkElement(element);
    } else if (matches(element, buttonDisableSelector) || matches(element, formEnableSelector)) {
      return enableFormElement(element);
    } else if (matches(element, formSubmitSelector)) {
      return enableFormElements(element);
    }
  };
  const disableElement = e => {
    const element = e instanceof Event ? e.target : e;
    if (isContentEditable(element)) {
      return;
    }
    if (matches(element, linkDisableSelector)) {
      return disableLinkElement(element);
    } else if (matches(element, buttonDisableSelector) || matches(element, formDisableSelector)) {
      return disableFormElement(element);
    } else if (matches(element, formSubmitSelector)) {
      return disableFormElements(element);
    }
  };
  var disableLinkElement = function(element) {
    if (getData(element, "ujs:disabled")) {
      return;
    }
    const replacement = element.getAttribute("data-disable-with");
    if (replacement != null) {
      setData(element, "ujs:enable-with", element.innerHTML);
      element.innerHTML = replacement;
    }
    element.addEventListener("click", stopEverything);
    return setData(element, "ujs:disabled", true);
  };
  var enableLinkElement = function(element) {
    const originalText = getData(element, "ujs:enable-with");
    if (originalText != null) {
      element.innerHTML = originalText;
      setData(element, "ujs:enable-with", null);
    }
    element.removeEventListener("click", stopEverything);
    return setData(element, "ujs:disabled", null);
  };
  var disableFormElements = form => formElements(form, formDisableSelector).forEach(disableFormElement);
  var disableFormElement = function(element) {
    if (getData(element, "ujs:disabled")) {
      return;
    }
    const replacement = element.getAttribute("data-disable-with");
    if (replacement != null) {
      if (matches(element, "button")) {
        setData(element, "ujs:enable-with", element.innerHTML);
        element.innerHTML = replacement;
      } else {
        setData(element, "ujs:enable-with", element.value);
        element.value = replacement;
      }
    }
    element.disabled = true;
    return setData(element, "ujs:disabled", true);
  };
  var enableFormElements = form => formElements(form, formEnableSelector).forEach((element => enableFormElement(element)));
  var enableFormElement = function(element) {
    const originalText = getData(element, "ujs:enable-with");
    if (originalText != null) {
      if (matches(element, "button")) {
        element.innerHTML = originalText;
      } else {
        element.value = originalText;
      }
      setData(element, "ujs:enable-with", null);
    }
    element.disabled = false;
    return setData(element, "ujs:disabled", null);
  };
  var isXhrRedirect = function(event) {
    const xhr = event.detail ? event.detail[0] : undefined;
    return xhr && xhr.getResponseHeader("X-Xhr-Redirect");
  };
  const handleMethodWithRails = rails => function(e) {
    const link = this;
    const method = link.getAttribute("data-method");
    if (!method) {
      return;
    }
    if (isContentEditable(this)) {
      return;
    }
    const href = rails.href(link);
    const csrfToken$1 = csrfToken();
    const csrfParam$1 = csrfParam();
    const form = document.createElement("form");
    let formContent = `<input name='_method' value='${method}' type='hidden' />`;
    if (csrfParam$1 && csrfToken$1 && !isCrossDomain(href)) {
      formContent += `<input name='${csrfParam$1}' value='${csrfToken$1}' type='hidden' />`;
    }
    formContent += '<input type="submit" />';
    form.method = "post";
    form.action = href;
    form.target = link.target;
    form.innerHTML = formContent;
    form.style.display = "none";
    document.body.appendChild(form);
    form.querySelector('[type="submit"]').click();
    stopEverything(e);
  };
  const isRemote = function(element) {
    const value = element.getAttribute("data-remote");
    return value != null && value !== "false";
  };
  const handleRemoteWithRails = rails => function(e) {
    let data, method, url;
    const element = this;
    if (!isRemote(element)) {
      return true;
    }
    if (!fire(element, "ajax:before")) {
      fire(element, "ajax:stopped");
      return false;
    }
    if (isContentEditable(element)) {
      fire(element, "ajax:stopped");
      return false;
    }
    const withCredentials = element.getAttribute("data-with-credentials");
    const dataType = element.getAttribute("data-type") || "script";
    if (matches(element, formSubmitSelector)) {
      const button = getData(element, "ujs:submit-button");
      method = getData(element, "ujs:submit-button-formmethod") || element.getAttribute("method") || "get";
      url = getData(element, "ujs:submit-button-formaction") || element.getAttribute("action") || location.href;
      if (method.toUpperCase() === "GET") {
        url = url.replace(/\?.*$/, "");
      }
      if (element.enctype === "multipart/form-data") {
        data = new FormData(element);
        if (button != null) {
          data.append(button.name, button.value);
        }
      } else {
        data = serializeElement(element, button);
      }
      setData(element, "ujs:submit-button", null);
      setData(element, "ujs:submit-button-formmethod", null);
      setData(element, "ujs:submit-button-formaction", null);
    } else if (matches(element, buttonClickSelector) || matches(element, inputChangeSelector)) {
      method = element.getAttribute("data-method");
      url = element.getAttribute("data-url");
      data = serializeElement(element, element.getAttribute("data-params"));
    } else {
      method = element.getAttribute("data-method");
      url = rails.href(element);
      data = element.getAttribute("data-params");
    }
    ajax({
      type: method || "GET",
      url: url,
      data: data,
      dataType: dataType,
      beforeSend(xhr, options) {
        if (fire(element, "ajax:beforeSend", [ xhr, options ])) {
          return fire(element, "ajax:send", [ xhr ]);
        } else {
          fire(element, "ajax:stopped");
          return false;
        }
      },
      success(...args) {
        return fire(element, "ajax:success", args);
      },
      error(...args) {
        return fire(element, "ajax:error", args);
      },
      complete(...args) {
        return fire(element, "ajax:complete", args);
      },
      crossDomain: isCrossDomain(url),
      withCredentials: withCredentials != null && withCredentials !== "false"
    });
    stopEverything(e);
  };
  const formSubmitButtonClick = function(e) {
    const button = this;
    const {form: form} = button;
    if (!form) {
      return;
    }
    if (button.name) {
      setData(form, "ujs:submit-button", {
        name: button.name,
        value: button.value
      });
    }
    setData(form, "ujs:formnovalidate-button", button.formNoValidate);
    setData(form, "ujs:submit-button-formaction", button.getAttribute("formaction"));
    return setData(form, "ujs:submit-button-formmethod", button.getAttribute("formmethod"));
  };
  const preventInsignificantClick = function(e) {
    const link = this;
    const method = (link.getAttribute("data-method") || "GET").toUpperCase();
    const data = link.getAttribute("data-params");
    const metaClick = e.metaKey || e.ctrlKey;
    const insignificantMetaClick = metaClick && method === "GET" && !data;
    const nonPrimaryMouseClick = e.button != null && e.button !== 0;
    if (nonPrimaryMouseClick || insignificantMetaClick) {
      e.stopImmediatePropagation();
    }
  };
  const Rails = {
    $: $,
    ajax: ajax,
    buttonClickSelector: buttonClickSelector,
    buttonDisableSelector: buttonDisableSelector,
    confirm: confirm,
    cspNonce: cspNonce,
    csrfToken: csrfToken,
    csrfParam: csrfParam,
    CSRFProtection: CSRFProtection,
    delegate: delegate,
    disableElement: disableElement,
    enableElement: enableElement,
    fileInputSelector: fileInputSelector,
    fire: fire,
    formElements: formElements,
    formEnableSelector: formEnableSelector,
    formDisableSelector: formDisableSelector,
    formInputClickSelector: formInputClickSelector,
    formSubmitButtonClick: formSubmitButtonClick,
    formSubmitSelector: formSubmitSelector,
    getData: getData,
    handleDisabledElement: handleDisabledElement,
    href: href,
    inputChangeSelector: inputChangeSelector,
    isCrossDomain: isCrossDomain,
    linkClickSelector: linkClickSelector,
    linkDisableSelector: linkDisableSelector,
    loadCSPNonce: loadCSPNonce,
    matches: matches,
    preventInsignificantClick: preventInsignificantClick,
    refreshCSRFTokens: refreshCSRFTokens,
    serializeElement: serializeElement,
    setData: setData,
    stopEverything: stopEverything
  };
  const handleConfirm = handleConfirmWithRails(Rails);
  Rails.handleConfirm = handleConfirm;
  const handleMethod = handleMethodWithRails(Rails);
  Rails.handleMethod = handleMethod;
  const handleRemote = handleRemoteWithRails(Rails);
  Rails.handleRemote = handleRemote;
  const start = function() {
    if (window._rails_loaded) {
      throw new Error("rails-ujs has already been loaded!");
    }
    window.addEventListener("pageshow", (function() {
      $(formEnableSelector).forEach((function(el) {
        if (getData(el, "ujs:disabled")) {
          enableElement(el);
        }
      }));
      $(linkDisableSelector).forEach((function(el) {
        if (getData(el, "ujs:disabled")) {
          enableElement(el);
        }
      }));
    }));
    delegate(document, linkDisableSelector, "ajax:complete", enableElement);
    delegate(document, linkDisableSelector, "ajax:stopped", enableElement);
    delegate(document, buttonDisableSelector, "ajax:complete", enableElement);
    delegate(document, buttonDisableSelector, "ajax:stopped", enableElement);
    delegate(document, linkClickSelector, "click", preventInsignificantClick);
    delegate(document, linkClickSelector, "click", handleDisabledElement);
    delegate(document, linkClickSelector, "click", handleConfirm);
    delegate(document, linkClickSelector, "click", disableElement);
    delegate(document, linkClickSelector, "click", handleRemote);
    delegate(document, linkClickSelector, "click", handleMethod);
    delegate(document, buttonClickSelector, "click", preventInsignificantClick);
    delegate(document, buttonClickSelector, "click", handleDisabledElement);
    delegate(document, buttonClickSelector, "click", handleConfirm);
    delegate(document, buttonClickSelector, "click", disableElement);
    delegate(document, buttonClickSelector, "click", handleRemote);
    delegate(document, inputChangeSelector, "change", handleDisabledElement);
    delegate(document, inputChangeSelector, "change", handleConfirm);
    delegate(document, inputChangeSelector, "change", handleRemote);
    delegate(document, formSubmitSelector, "submit", handleDisabledElement);
    delegate(document, formSubmitSelector, "submit", handleConfirm);
    delegate(document, formSubmitSelector, "submit", handleRemote);
    delegate(document, formSubmitSelector, "submit", (e => setTimeout((() => disableElement(e)), 13)));
    delegate(document, formSubmitSelector, "ajax:send", disableElement);
    delegate(document, formSubmitSelector, "ajax:complete", enableElement);
    delegate(document, formInputClickSelector, "click", preventInsignificantClick);
    delegate(document, formInputClickSelector, "click", handleDisabledElement);
    delegate(document, formInputClickSelector, "click", handleConfirm);
    delegate(document, formInputClickSelector, "click", formSubmitButtonClick);
    document.addEventListener("DOMContentLoaded", refreshCSRFTokens);
    document.addEventListener("DOMContentLoaded", loadCSPNonce);
    return window._rails_loaded = true;
  };
  Rails.start = start;
  if (typeof jQuery !== "undefined" && jQuery && jQuery.ajax) {
    if (jQuery.rails) {
      throw new Error("If you load both jquery_ujs and rails-ujs, use rails-ujs only.");
    }
    jQuery.rails = Rails;
    jQuery.ajaxPrefilter((function(options, originalOptions, xhr) {
      if (!options.crossDomain) {
        return CSRFProtection(xhr);
      }
    }));
  }
  if (typeof exports !== "object" && typeof module === "undefined") {
    window.Rails = Rails;
    if (fire(document, "rails:attachBindings")) {
      start();
    }
  }
  return Rails;
}));
// Functions for working with mapboxgl maps.

function populateMapboxGLMap(mapID, mapData, mapType) {
  // Accepts GeoJSON mapData and a mapType, and populates a mapID div.
  
  const mapPosition = mapCenterZoomBounds(mapData);
  const mapContainer = 'mapbox_' + mapID;
  
  const map = new mapboxgl.Map({
    container: mapContainer,
    style: 'mapbox://styles/bogardpd/cly0gib62008301p82kk64np1', // Light Terrain - Flight Historian
    bounds: [
      [mapPosition['bounds']['w'], mapPosition['bounds']['s']],
      [mapPosition['bounds']['e'], mapPosition['bounds']['n']],
    ],
    fitBoundsOptions: {
      padding: {top: 40, bottom: 40, left: 40, right: 40},
      minZoom: 0.49, // Min zoom for initial bounds
      maxZoom: 6.00, // Max zoom for initial bounds
    },
    minZoom: 0.49, // Min zoom user can zoom to
    maxZoom: 8.00, // Max zoom user can zoom to
  });

  map.on('load', () => {
    // Load data.
    map.addSource('flights', {
      'type': 'geojson',
      'data': mapData,
      'generateId': true,
    })

    // Add routes.
    map.addLayer({
      'id': 'routes',
      'type': 'line',
      'source': 'flights',
      'filter': ['==', '$type', 'LineString'],
      'paint': {
        'line-width': {
          'property': 'Highlighted',
          'type': 'categorical',
          'stops': [
            [{'zoom':  4, 'value': true },  4.0],
            [{'zoom':  4, 'value': false},  1.5],
            [{'zoom': 20, 'value': true }, 12.0],
            [{'zoom': 20, 'value': false},  5.0],
          ],
        },
        'line-color': '#0077bb',
        'line-opacity': ['case', ['get', 'Highlighted'], 1.0, 0.8],
      }
    });

    if (mapType == 'airport-frequency-map') {
      var circleRadius = [
        'interpolate', ['linear'], ['zoom'],
        0, ['*', 2.0, ['sqrt', ['get', 'AirportVisitCount']]],
        10, ['*', 8.0, ['sqrt', ['get', 'AirportVisitCount']]]
      ];
      var circleOpacity = 0.5;
      var textVariableAnchor = ['center'];
    } else {
      var circleRadius = {
        'property': 'Highlighted',
        'type': 'categorical',
        'stops': [
          [{'zoom':  4, 'value': true }, 4],
          [{'zoom':  4, 'value': false}, 3],
          [{'zoom': 20, 'value': true }, 24],
          [{'zoom': 20, 'value': false}, 12],
        ],
      };
      var circleOpacity = 1.0;
      var textVariableAnchor = ['bottom','top','left','right'];
    }

    // Add airports.
    map.addLayer({
      'id': 'airports',
      'type': 'circle',
      'source': 'flights',
      'filter': ['==', '$type', 'Point'],
      'paint': {
        'circle-radius': circleRadius,
        'circle-color': '#000000',
        'circle-stroke-color': '#0077bb',
        'circle-stroke-width': 1,
        'circle-opacity': circleOpacity,
      }
    });

    var labelMinzoom = (mapType == 'single-flight-map') ? 0 : 3;

    // Add labels.
    map.addLayer({
      'id': 'airport-labels',
      'type': 'symbol',
      'source': 'flights',
      'filter': ['==', '$type', 'Point'],
      'minzoom': labelMinzoom,
      'layout': {
        'text-field': ['get', 'AirportIATA'],
        'text-variable-anchor': textVariableAnchor,
        'text-radial-offset': {
          'property': 'Highlighted',
          'type': 'categorical',
          'stops': [
            [{'zoom':  4, 'value': true }, 0.3],
            [{'zoom':  4, 'value': false}, 0.3],
            [{'zoom': 20, 'value': true }, 1.8],
            [{'zoom': 20, 'value': false}, 1.2],
          ],
        },
        'text-font': [
          'case',
          ['get', 'Highlighted'],
          ['literal', ['Source Sans Pro Semibold', 'DIN Pro Bold', 'Arial Unicode MS Bold']],
          ['literal', ['Source Sans Pro Regular', 'DIN Pro Regular', 'Arial Unicode MS Regular']],
        ],
        'text-size': ['case', ['get', 'Highlighted'], 15, 13],
        'symbol-sort-key': ['case', ['get', 'Highlighted'], 0, 1], // Lower value is higher priority
      },
      'paint': {
        'text-color': '#000000',
        'text-halo-color': '#ffffff',
        'text-halo-width': 1.5,
        'text-halo-blur': 2,
      },
    });

  });
}

function mapCenterZoomBounds(geoJSONData) {
  const defaultValues = {center: [0, 20], zoom: 0.5, bounds: {w: -180.0, e: 180.0, n: 80.0, s: -70.0}};
  let bounds = defaultValues['bounds'];
  // Get features.
  let features = geoJSONData['features'];
  let routes = features.filter(r => r['geometry']['type'] == 'MultiLineString');
  let airports = features.filter(r => r['geometry']['type'] == 'Point');
  
  if (routes.length == 0 && airports.length == 0) {
    return defaultValues;
  }
  bounds = airportCollectionBounds(airports, bounds);

  // Generate Map of longitudes and their changes in count.
  let hasAirportAt180 = false;
  let changes = new Map();
  let minLats = [];
  let maxLats = [];
  routes.forEach((route) => {
    let multiline = route['geometry']['coordinates'];
    multiline.forEach((line) => {
      if (line.length > 0) {
        let lats = line.map(val => val[1]);
        minLats.push(Math.min.apply(Math, lats));
        maxLats.push(Math.max.apply(Math, lats));
        lonRange = [line[0][0], line[line.length - 1][0]].sort(function(a,b) {return a - b});
        changes.set(lonRange[0], changes.has(lonRange[0]) ? changes.get(lonRange[0]) + 1 : 1);
        changes.set(lonRange[1], changes.has(lonRange[1]) ? changes.get(lonRange[1]) - 1 : -1);
        if (multiline.length == 1 && (lonRange[0] == -180 || lonRange[1] == 180)) {
            hasAirportAt180 = true;
        }
      }
    });
  })

  // Generate map of starting (westernmost) longitudes and their total route count.
  let longitudes = Array.from(changes.keys()).sort(function(a,b) {return a - b});
  let currentCount = 0
  let lonRouteCount = new Map();
  longitudes.forEach((lon) => {
    currentCount = currentCount + changes.get(lon);
    lonRouteCount.set(lon, currentCount);
  });

  // Remove antemeridian if no airports are exactly at longitude 180.
  if (!hasAirportAt180) {
    if (longitudes[0] == -180) {
      longitudes.splice(0, 1);
      lonRouteCount.delete(-180);
    }
    if (longitudes[longitudes.length - 1] == 180) {
      longitudes.splice(longitudes.length - 1, 1);
      lonRouteCount.delete(180);
    }
  }

  // Create array of [longitude, width, routeCount] arrays.
  let lonStartValues = [];
  for (let i = 0; i < longitudes.length; i++) {
    let width = (i == longitudes.length - 1) ? longitudes[0] + 360 - longitudes[i] : longitudes[i + 1] - longitudes[i];
    lonStartValues.push([longitudes[i], width, lonRouteCount.get(longitudes[i])]);
  }

  // Select regions with lowest routeCounts, then sort by width descending.
  lonStartValues = lonStartValues.filter(l => l[2] == Math.min(...lonRouteCount.values()))
  lonStartValues = lonStartValues.sort(function(a, b) {return b[1] - a[1]});

  // Calculate central longitude and bounds.
  let lonCenter = defaultValues['center'][0];
  let boundW = defaultValues['bounds']['w'];
  let boundE = defaultValues['bounds']['e'];
  let boundN = defaultValues['bounds']['n'];
  let boundS = defaultValues['bounds']['s'];
  if (lonStartValues.length > 0) {
    // Get center of of the widest of the lowest routeCount regions.
    lonCenter = lonStartValues[0][0] + (lonStartValues[0][1] / 2) + 180;
    while (lonCenter >= 180) {
      lonCenter = lonCenter - 360;
    }

    // Calculate bounds.
    if (lonStartValues[0][2] == 0) {
      boundE = lonStartValues[0][0];
      boundW = boundE + lonStartValues[0][1] - 360;
    } else {
      // Map goes around the world, so set east and west to center of lowest count region.
      boundE = lonCenter + 180;
      boundW = lonCenter - 180;
    }
    boundN = (maxLats.length > 0) ? Math.max.apply(Math, maxLats) : defaultValues['bounds']['n'];
    boundS = (minLats.length > 0) ? Math.min.apply(Math, minLats) : defaultValues['bounds']['s'];
    bounds = {w: boundW, e: boundE, n: boundN, s: boundS};
  }
  
  return {center: [lonCenter, 20], zoom: 0.5, bounds: bounds};
}

function airportCollectionBounds(airports, defaultBounds) {
  if (airports.length == 0) {
    return defaultBounds;
  } else if (airports.length == 1) {
    let coords = airports[0]['geometry']['coordinates']
    return {w: coords[0], e: coords[0], n: coords[1], s: coords[1]};
  }
  let lons = airports.map(airport => airport['geometry']['coordinates'][0]);
  let lats = airports.map(airport => airport['geometry']['coordinates'][1]);
  
  let lonsSorted = lons.sort(function(a,b) {return a - b});
  let lonsExtended = [...lonsSorted, (lonsSorted[0] + 360.0)];
  let lonWidths = lonsSorted.map((lon, i) => lonsExtended[i + 1] - lon);
  let biggestGapStartIndex = lonWidths.indexOf(Math.max.apply(Math, lonWidths));
  let boundE = lonsSorted[biggestGapStartIndex];
  let boundW = lonsSorted[(biggestGapStartIndex + 1) % lonsSorted.length];
  if (boundE < boundW) {
    boundE = boundE + 360.0;
  }
  let boundN = Math.max.apply(Math, lats);
  let boundS = Math.min.apply(Math, lats);

  return {w: boundW, e: boundE, n: boundN, s: boundS};
};
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//

;
