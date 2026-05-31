'use strict';

require('bpmn-js/dist/assets/bpmn-js.css');
require('bpmn-js/dist/assets/diagram-js.css');
require('bpmn-js/dist/assets/bpmn-font/css/bpmn-embedded.css');

const BpmnModeler = require('bpmn-js/lib/Modeler').default || require('bpmn-js/lib/Modeler');

window.addEventListener('DOMContentLoaded', async () => {
  const canvas = document.getElementById('canvas');
  const loading = document.getElementById('loading');
  const errorMsg = document.getElementById('error-msg');

  const modeler = new BpmnModeler({ container: canvas });

  try {
    const res = await fetch('./diagrams/user_signup_flow.bpmn');
    if (!res.ok) {
      throw new Error(`${res.status} ${res.statusText}`);
    }
    const xml = await res.text();
    loading.textContent = '図を描画しています...';

    const { warnings } = await modeler.importXML(xml);
    if (warnings.length) {
      console.warn('BPMN import warnings:', warnings);
    }

    modeler.get('canvas').zoom('fit-viewport');
    loading.style.display = 'none';
  } catch (err) {
    console.error('BPMN 図の表示でエラーが発生しました:', err);
    loading.style.display = 'none';
    errorMsg.style.display = 'block';
    errorMsg.innerHTML =
      '<strong>BPMN 図の表示に失敗しました</strong><br><small>' +
      err.message +
      '</small>';
  }

  document.getElementById('btn-svg').addEventListener('click', async () => {
    try {
      const { svg } = await modeler.saveSVG();
      const blob = new Blob([svg], { type: 'image/svg+xml' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'user_signup_flow.svg';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('SVG の書き出しに失敗しました:', err);
    }
  });

  document.getElementById('btn-download').addEventListener('click', async () => {
    try {
      const { xml } = await modeler.saveXML({ format: true });
      const blob = new Blob([xml], { type: 'application/xml' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'user_signup_flow.bpmn';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('XML の書き出しに失敗しました:', err);
    }
  });
});
