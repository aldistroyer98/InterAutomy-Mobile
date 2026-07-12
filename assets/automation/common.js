(function () {
  'use strict';

  function findFirstSelector(alternatives) {
    for (const selector of alternatives || []) {
      try {
        const element = document.querySelector(selector);
        if (element) return { element: element, selector: selector };
      } catch (_) {}
    }
    return null;
  }

  function visible(element) {
    if (!element) return false;
    const style = window.getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    return style.visibility !== 'hidden' && style.display !== 'none' && rect.width > 0 && rect.height > 0;
  }

  function setNativeValue(element, value) {
    const prototype = element instanceof HTMLTextAreaElement
      ? HTMLTextAreaElement.prototype
      : HTMLInputElement.prototype;
    const setter = Object.getOwnPropertyDescriptor(prototype, 'value')?.set;
    if (setter) setter.call(element, value); else element.value = value;
  }

  function dispatchInputEvents(element) {
    element.dispatchEvent(new Event('input', { bubbles: true }));
    element.dispatchEvent(new Event('change', { bubbles: true }));
    element.dispatchEvent(new Event('blur', { bubbles: true }));
  }

  function clickElement(element) {
    if (!visible(element) || element.disabled) return false;
    element.scrollIntoView({ block: 'center', inline: 'nearest' });
    element.click();
    return true;
  }

  function selectOption(element, value) {
    if (!(element instanceof HTMLSelectElement)) return false;
    const option = Array.from(element.options).find((item) => item.value === value || item.text === value);
    if (!option) return false;
    element.value = option.value;
    dispatchInputEvents(element);
    return element.value === option.value;
  }

  function readText(element) { return element ? (element.innerText || element.textContent || '').trim() : ''; }
  function readValue(element) { return element && 'value' in element ? String(element.value || '') : ''; }

  function waitForSelector(alternatives, timeoutMs) {
    const timeout = timeoutMs || 10000;
    return new Promise((resolve) => {
      const found = findFirstSelector(alternatives);
      if (found) return resolve(found.selector);
      const observer = new MutationObserver(() => {
        const next = findFirstSelector(alternatives);
        if (next) { observer.disconnect(); resolve(next.selector); }
      });
      observer.observe(document.documentElement, { childList: true, subtree: true, attributes: true });
      window.setTimeout(() => { observer.disconnect(); resolve(null); }, timeout);
    });
  }

  function waitForDomIdle(idleMs) {
    const quietFor = idleMs || 300;
    return new Promise((resolve) => {
      let timer = window.setTimeout(done, quietFor);
      const observer = new MutationObserver(() => {
        window.clearTimeout(timer);
        timer = window.setTimeout(done, quietFor);
      });
      function done() { observer.disconnect(); resolve(true); }
      observer.observe(document.documentElement, { childList: true, subtree: true, attributes: true, characterData: true });
    });
  }

  function detectFramework() {
    if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) return 'react';
    if (window.ng || document.querySelector('[ng-version]')) return 'angular';
    if (window.__VUE__ || document.querySelector('[data-v-app]')) return 'vue';
    return 'unknown';
  }

  function observeMutations(callback) {
    const observer = new MutationObserver((records) => callback(records.length));
    observer.observe(document.documentElement, { childList: true, subtree: true, attributes: true });
    return () => observer.disconnect();
  }

  function inspectPage(includeText) {
    return {
      url: location.href,
      title: document.title || '',
      iframes: document.querySelectorAll('iframe, frame').length,
      fileInputs: document.querySelectorAll('input[type="file"]').length,
      popupLinks: document.querySelectorAll('a[target="_blank"]').length,
      hasPasswordInput: Boolean(document.querySelector('input[type="password"]')),
      hasOrderNumber: Boolean(findFirstSelector(['#form_field_groups_nro_oc', 'input[name="nro_oc"]'])),
      hasCompleteButton: Boolean(findFirstSelector(['button.ant-btn.ant-btn-primary.antd-pro-pages-applications-continue-style-complete', '[data-testid="complete-order"]'])),
      text: includeText ? (document.body?.innerText || '').slice(0, 1200) : '',
      cookieEnabled: navigator.cookieEnabled,
      userAgent: navigator.userAgent.slice(0, 180),
      framework: detectFramework()
    };
  }

  window.__interautomyAutomation = Object.freeze({
    version: '1', findFirstSelector: findFirstSelector, visible: visible,
    elementIsVisible: visible, setNativeValue: setNativeValue,
    setInputValue: setNativeValue, dispatchInputEvents: dispatchInputEvents,
    clickElement: clickElement, selectOption: selectOption, readText: readText,
    readValue: readValue, waitForSelector: waitForSelector,
    waitForDomIdle: waitForDomIdle, detectFramework: detectFramework,
    observeMutations: observeMutations, inspectPage: inspectPage
  });
})();
