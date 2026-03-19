'use strict';

const ALIGN_API = '/exist/apps/klee-sync/src/api/alignments.xql';

let currentTEI        = '';
let currentProject    = null;
let previewingVersion = null;
let previewXml        = '';
let restoreZipFile    = null;

const syncConfigModal = new bootstrap.Modal('#syncConfigModal');
const saveAlignModal  = new bootstrap.Modal('#saveAlignModal');
const restoreModal    = new bootstrap.Modal('#restoreModal');
const helpModal       = new bootstrap.Modal('#helpModal');
const toastEl         = document.getElementById('toast');
const bsToast         = new bootstrap.Toast(toastEl, { delay: 3500 });

function notify(msg, type) {
  if (!type) type = 'success';
  toastEl.className = 'toast align-items-center text-white border-0 bg-' + type;
  document.getElementById('toastMsg').textContent = msg;
  bsToast.show();
}

function esc(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function enc(s) { return encodeURIComponent(s); }

function addLineNumbers(text) {
  return text.split('\n').map(function(l) { return '<span>' + l.replace(/</g,'&lt;').replace(/>/g,'&gt;') + '</span>'; }).join('');
}

function fmtTs(ts) {
  if (!ts || ts.length < 15) return ts || '—';
  return ts.slice(6,8) + '/' + ts.slice(4,6) + '/' + ts.slice(0,4) + ' ' + ts.slice(9,11) + ':' + ts.slice(11,13) + ':' + ts.slice(13,15);
}

function dlBlob(content, filename, mime) {
  if (!mime) mime = 'application/xml';
  var url = URL.createObjectURL(new Blob([content], { type: mime }));
  var a = document.createElement('a');
  a.href = url; a.download = filename; a.style.display = 'none';
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

var syncGroup    = document.getElementById('syncGroup');
var downloadBtn  = document.getElementById('downloadBtn');
var saveAlignBtn = document.getElementById('saveAlignBtn');

document.getElementById('mainTabs').addEventListener('click', function(e) {
  var link = e.target.closest('[data-tab]');
  if (!link) return;
  e.preventDefault();
  var tab = link.dataset.tab;
  document.querySelectorAll('.tab-pane-content').forEach(function(p) { p.classList.add('d-none'); });
  document.getElementById('pane-' + tab).classList.remove('d-none');
  document.querySelectorAll('#mainTabs .nav-link').forEach(function(l) { l.classList.remove('active'); });
  link.classList.add('active');
  var isConversion = tab === 'conversion';
  syncGroup.classList.toggle('d-none', !isConversion);
  downloadBtn.classList.toggle('d-none', !isConversion);
  saveAlignBtn.classList.toggle('d-none', isConversion);
  if (!isConversion) loadProjectList();
});

var defaultConfig = { resourceUrl: 'https://existdb2.websoupcloud.it/exist/apps/klee/data/annoParsed.xml', username: '', password: '', proxyUrl: '' };
var currentConfig = Object.assign({}, defaultConfig);

function loadConfigForm(cfg) {
  if (!cfg) cfg = defaultConfig;
  document.getElementById('resourceUrl').value = cfg.resourceUrl;
  document.getElementById('username').value    = cfg.username;
  document.getElementById('password').value    = cfg.password;
  document.getElementById('proxyUrl').value    = cfg.proxyUrl || '';
}

async function convertFile(file) {
  if (!file) return;
  document.querySelector('#sourceContent code').innerHTML = addLineNumbers(await file.text());
  var formData = new FormData();
  formData.append('file', file);
  try {
    var resp = await fetch('/exist/apps/klee-sync/src/api/transform.xql', { method: 'POST', body: formData });
    if (!resp.ok) throw new Error('Server error: ' + resp.status);
    currentTEI = await resp.text();
    document.querySelector('#convertedContent code').innerHTML = addLineNumbers(currentTEI);
  } catch (err) { notify('Conversion failed: ' + err.message, 'danger'); }
}

document.getElementById('sourceFile').addEventListener('change', function(e) { convertFile(e.target.files[0]); });
downloadBtn.addEventListener('click', function() { if (currentTEI) dlBlob(currentTEI, 'converted.xml'); });
document.getElementById('configureSync').addEventListener('click', function(e) { e.preventDefault(); loadConfigForm(currentConfig); syncConfigModal.show(); });
document.getElementById('resetConfig').addEventListener('click', function() { loadConfigForm(defaultConfig); });
document.getElementById('saveConfig').addEventListener('click', function() {
  var f = document.getElementById('syncConfigForm');
  currentConfig = { resourceUrl: f.resourceUrl.value, username: f.username.value, password: f.password.value, proxyUrl: f.proxyUrl.value };
  syncConfigModal.hide(); notify('Configuration saved');
});

document.getElementById('syncBtn').addEventListener('click', async function() {
  try {
    var targetUrl = currentConfig.proxyUrl ? currentConfig.proxyUrl + '?url=' + enc(currentConfig.resourceUrl) : currentConfig.resourceUrl;
    var xml = await (await fetch(targetUrl)).text();
    document.querySelector('#convertedContent code').innerHTML = addLineNumbers(xml);
    notify('Sync complete');
  } catch (err) { notify(err.message, 'danger'); }
});

async function loadProjectList() {
  var list = document.getElementById('projectList');
  list.innerHTML = '<div class="text-muted small p-3">Loading...</div>';
  try {
    var projects = await (await fetch(ALIGN_API + '?action=list')).json();
    var sel = document.getElementById('saveProjectSelect');
    var prev = sel.value;
    sel.innerHTML = '<option value="">— select project —</option>';
    projects.forEach(function(p) {
      var opt = document.createElement('option');
      opt.value = p.name; opt.textContent = p.name; sel.appendChild(opt);
    });
    if (prev) sel.value = prev;
    if (!projects.length) { list.innerHTML = '<div class="text-muted small p-3">No projects yet.</div>'; return; }
    list.innerHTML = '';
    projects.forEach(function(p) {
      var active = currentProject && currentProject.name === p.name;
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'list-group-item list-group-item-action px-3 py-2' + (active ? ' active' : '');
      btn.dataset.project = p.name;
      btn.innerHTML = '<div class="d-flex justify-content-between align-items-start">' +
        '<div class="text-truncate me-2"><strong class="d-block text-truncate">' + esc(p.name) + '</strong>' +
        '<small class="' + (active ? 'opacity-75' : 'text-muted') + '">' + esc(p.langs || '—') + '</small></div>' +
        '<div class="text-end flex-shrink-0"><span class="badge bg-' + (active ? 'light text-dark' : 'secondary') + '">' + p.alignments + '</span>' +
        '<div class="' + (active ? 'opacity-75' : 'text-muted') + '" style="font-size:.7rem"><i class="bi bi-clock-history"></i> ' + p.versions + 'v</div></div></div>';
      btn.addEventListener('click', function() { selectProject(p); });
      list.appendChild(btn);
    });
  } catch (err) { list.innerHTML = '<div class="text-danger small p-3">Error: ' + esc(err.message) + '</div>'; }
}

async function selectProject(p) {
  currentProject = p; previewingVersion = null; previewXml = '';
  document.getElementById('alignEmpty').classList.add('d-none');
  document.getElementById('alignDetail').classList.remove('d-none');
  document.getElementById('detailTitle').textContent = p.name;
  document.getElementById('detailMeta').textContent = p.alignments + ' alignment' + (p.alignments === 1 ? '' : 's') + ' · ' + (p.langs || '—') + ' · ' + p.versions + ' version' + (p.versions === 1 ? '' : 's');
  document.querySelectorAll('#projectList .list-group-item').forEach(function(el) { el.classList.toggle('active', el.dataset.project === p.name); });
  await Promise.all([loadVersionList(p.name), loadCurrentPreview(p.name)]);
}

async function loadVersionList(projectName) {
  var list = document.getElementById('versionList');
  list.innerHTML = '<div class="text-muted small p-3">Loading...</div>';
  try {
    var versions = await (await fetch(ALIGN_API + '?action=versions&project=' + enc(projectName))).json();
    if (!versions.length) { list.innerHTML = '<div class="text-muted small p-3">No versions saved yet.</div>'; return; }
    list.innerHTML = '';
    versions.forEach(function(v, i) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'list-group-item list-group-item-action px-3 py-2';
      btn.dataset.vfile = v.file;
      var badge = i === 0 ? ' <span class="badge bg-primary ms-1">latest</span>' : '';
      btn.innerHTML = '<div class="d-flex justify-content-between align-items-center">' +
        '<div><div class="fw-semibold" style="font-size:.85rem">' + fmtTs(v.timestamp) + badge + '</div>' +
        '<div class="text-muted" style="font-size:.75rem">' + (v.size/1024).toFixed(1) + ' KB</div></div>' +
        '<i class="bi bi-chevron-right text-muted"></i></div>';
      btn.addEventListener('click', function() { loadVersionPreview(projectName, v.file, btn); });
      list.appendChild(btn);
    });
  } catch (err) { list.innerHTML = '<div class="text-danger small p-3">Error: ' + esc(err.message) + '</div>'; }
}

async function loadCurrentPreview(projectName) {
  document.getElementById('previewLabel').textContent = 'Current version';
  document.getElementById('restoreVersionBtn').classList.add('d-none');
  previewingVersion = null;
  try {
    var resp = await fetch(ALIGN_API + '?action=get&project=' + enc(projectName));
    if (!resp.ok) { document.querySelector('#previewContent code').innerHTML = '<span class="text-muted">No file saved yet.</span>'; return; }
    previewXml = await resp.text();
    document.querySelector('#previewContent code').innerHTML = addLineNumbers(previewXml);
  } catch (err) { document.querySelector('#previewContent code').textContent = 'Error: ' + err.message; }
}

async function loadVersionPreview(projectName, vfile, btnEl) {
  document.querySelectorAll('#versionList .list-group-item').forEach(function(el) { el.classList.remove('active'); });
  btnEl.classList.add('active');
  var ts = vfile.replace(/^.+_(\d{8}T\d{6})\.xml$/, '$1');
  document.getElementById('previewLabel').textContent = 'Version ' + fmtTs(ts);
  document.getElementById('restoreVersionBtn').classList.remove('d-none');
  previewingVersion = vfile;
  try {
    previewXml = await (await fetch(ALIGN_API + '?action=get-version&project=' + enc(projectName) + '&version=' + enc(vfile))).text();
    document.querySelector('#previewContent code').innerHTML = addLineNumbers(previewXml);
  } catch (err) { document.querySelector('#previewContent code').textContent = 'Error: ' + err.message; }
}

document.getElementById('newProjectBtn').addEventListener('click', function() {
  var name = document.getElementById('newProjectName').value.trim();
  if (!name) return;
  document.getElementById('newProjectName').value = '';
  var sel = document.getElementById('saveProjectSelect');
  if (![].slice.call(sel.options).some(function(o) { return o.value === name; })) {
    var opt = document.createElement('option'); opt.value = name; opt.textContent = name; sel.appendChild(opt);
  }
  sel.value = name;
  currentProject = { name: name, alignments: 0, langs: '—', versions: 0 };
  document.getElementById('alignEmpty').classList.add('d-none');
  document.getElementById('alignDetail').classList.remove('d-none');
  document.getElementById('detailTitle').textContent = name;
  document.getElementById('detailMeta').textContent = 'New project — save the first TEI file';
  document.getElementById('versionList').innerHTML = '<div class="text-muted small p-3">No versions saved yet.</div>';
  document.querySelector('#previewContent code').innerHTML = '<span class="text-muted">Save the first file to begin.</span>';
  saveAlignModal.show();
});

document.getElementById('refreshListBtn').addEventListener('click', loadProjectList);

document.getElementById('downloadCurrentBtn').addEventListener('click', async function() {
  if (!currentProject) return;
  try { var xml = await (await fetch(ALIGN_API + '?action=get&project=' + enc(currentProject.name))).text(); dlBlob(xml, currentProject.name + '.xml'); }
  catch (err) { notify('Download error: ' + err.message, 'danger'); }
});

document.getElementById('downloadVersionBtn').addEventListener('click', function() {
  if (!previewXml) return;
  dlBlob(previewXml, previewingVersion || ((currentProject ? currentProject.name : 'export') + '.xml'));
});

document.getElementById('restoreVersionBtn').addEventListener('click', async function() {
  if (!currentProject || !previewingVersion || !previewXml) return;
  if (!confirm('Restore this version as current for "' + currentProject.name + '"?')) return;
  try {
    var resp = await fetch(ALIGN_API + '?action=save&project=' + enc(currentProject.name), { method: 'POST', body: previewXml, headers: { 'Content-Type': 'application/xml' } });
    var json = await resp.json();
    if (resp.ok) { notify('Version restored (' + fmtTs(json.timestamp) + ')'); selectProject(Object.assign({}, currentProject, { versions: currentProject.versions + 1 })); }
    else { notify(json.error || 'Error', 'danger'); }
  } catch (err) { notify(err.message, 'danger'); }
});

document.getElementById('deleteProjectBtn').addEventListener('click', async function() {
  if (!currentProject) return;
  if (!confirm('Delete "' + currentProject.name + '" and all its history? This cannot be undone.')) return;
  try {
    var resp = await fetch(ALIGN_API + '?action=delete&project=' + enc(currentProject.name), { method: 'DELETE' });
    var json = await resp.json();
    if (resp.ok) {
      notify('Project deleted'); currentProject = null;
      document.getElementById('alignDetail').classList.add('d-none');
      document.getElementById('alignEmpty').classList.remove('d-none');
      loadProjectList();
    } else { notify(json.error || 'Error', 'danger'); }
  } catch (err) { notify(err.message, 'danger'); }
});

saveAlignBtn.addEventListener('click', function() {
  if (currentProject) document.getElementById('saveProjectSelect').value = currentProject.name;
  saveAlignModal.show();
});
document.getElementById('saveAlignFile').addEventListener('change', async function(e) {
  var file = e.target.files[0];
  if (file) document.getElementById('saveAlignXml').value = await file.text();
});
document.getElementById('confirmSaveAlign').addEventListener('click', async function() {
  var projectName = document.getElementById('saveProjectSelect').value;
  var xml = document.getElementById('saveAlignXml').value.trim();
  if (!projectName) { notify('Select a project', 'warning'); return; }
  if (!xml) { notify('No XML content', 'warning'); return; }
  try {
    var resp = await fetch(ALIGN_API + '?action=save&project=' + enc(projectName), { method: 'POST', body: xml, headers: { 'Content-Type': 'application/xml' } });
    var json = await resp.json();
    if (resp.ok) {
      notify('Saved: version ' + fmtTs(json.timestamp) + ' (' + json.alignments + ' alignments)');
      saveAlignModal.hide();
      document.getElementById('saveAlignXml').value = '';
      document.getElementById('saveAlignFile').value = '';
      await loadProjectList();
      selectProject({ name: projectName, alignments: json.alignments, langs: '—', versions: (currentProject ? currentProject.versions : 0) + 1 });
    } else { notify(json.error || 'Save error', 'danger'); }
  } catch (err) { notify(err.message, 'danger'); }
});

document.getElementById('backupBtn').addEventListener('click', async function() {
  notify('Building backup...', 'secondary');
  try {
    var projects = await (await fetch(ALIGN_API + '?action=list')).json();
    if (!projects.length) { notify('No projects to back up', 'warning'); return; }
    var zip = new JSZip();
    for (var i = 0; i < projects.length; i++) {
      var p = projects[i];
      var folder = zip.folder(p.name);
      var curResp = await fetch(ALIGN_API + '?action=get&project=' + enc(p.name));
      if (curResp.ok) folder.file('current.xml', await curResp.text());
      var versions = await (await fetch(ALIGN_API + '?action=versions&project=' + enc(p.name))).json();
      var verFolder = folder.folder('versions');
      for (var j = 0; j < versions.length; j++) {
        var v = versions[j];
        var vResp = await fetch(ALIGN_API + '?action=get-version&project=' + enc(p.name) + '&version=' + enc(v.file));
        if (vResp.ok) verFolder.file(v.file, await vResp.text());
      }
    }
    var blob = await zip.generateAsync({ type: 'blob', compression: 'DEFLATE' });
    var ts = new Date().toISOString().replace(/[-:T]/g,'').slice(0,15);
    dlBlob(blob, 'klee-sync-backup-' + ts + '.zip', 'application/zip');
    notify('Backup complete — ' + projects.length + ' project' + (projects.length === 1 ? '' : 's'));
  } catch (err) { notify('Backup error: ' + err.message, 'danger'); }
});

document.getElementById('restoreBtn').addEventListener('click', function() {
  document.getElementById('restoreFile').click();
});
document.getElementById('restoreFile').addEventListener('change', function(e) {
  var file = e.target.files[0];
  if (!file) return;
  restoreZipFile = file;
  document.getElementById('restoreProgress').classList.add('d-none');
  document.getElementById('restoreResult').classList.add('d-none');
  document.getElementById('restoreResult').innerHTML = '';
  restoreModal.show();
  e.target.value = '';
});
document.getElementById('confirmRestore').addEventListener('click', async function() {
  if (!restoreZipFile) return;
  var progressEl = document.getElementById('restoreProgress');
  var barEl      = document.getElementById('restoreBar');
  var statusEl   = document.getElementById('restoreStatus');
  var resultEl   = document.getElementById('restoreResult');
  var confirmBtn = document.getElementById('confirmRestore');
  progressEl.classList.remove('d-none');
  resultEl.classList.add('d-none');
  confirmBtn.disabled = true;
  var log = [];
  var done = 0;
  try {
    var zip = await JSZip.loadAsync(restoreZipFile);
    var projectFolders = Object.keys(zip.files)
      .filter(function(p) { return zip.files[p].dir; })
      .map(function(p) { return p.replace(/\/$/, ''); })
      .filter(function(p) { return p.indexOf('/') === -1; });
    var total = projectFolders.length;
    for (var i = 0; i < projectFolders.length; i++) {
      var projectName = projectFolders[i];
      statusEl.textContent = 'Restoring "' + projectName + '"...';
      barEl.style.width = Math.round((done / total) * 100) + '%';
      var vFiles = Object.keys(zip.files)
        .filter(function(p) { return p.indexOf(projectName + '/versions/') === 0 && !zip.files[p].dir && p.slice(-4) === '.xml'; })
        .sort();
      for (var j = 0; j < vFiles.length; j++) {
        var vPath = vFiles[j];
        var xml = await zip.files[vPath].async('string');
        var fname = vPath.split('/').pop();
        var ts = fname.replace(/^.+_(\d{8}T\d{6})\.xml$/, '$1');
        var resp = await fetch(ALIGN_API + '?action=save&project=' + enc(projectName), { method: 'POST', body: xml, headers: { 'Content-Type': 'application/xml' } });
        var jResp = await resp.json();
        if (resp.ok) { log.push('<span class="text-success">&#10003;</span> ' + esc(projectName) + ' — ' + fmtTs(ts)); }
        else { log.push('<span class="text-danger">&#10007;</span> ' + esc(projectName) + ' — ' + fmtTs(ts) + ': ' + esc(jResp.error || 'error')); }
      }
      done++;
      barEl.style.width = Math.round((done / total) * 100) + '%';
    }
    statusEl.textContent = 'Done.';
    barEl.classList.add('bg-success');
    resultEl.innerHTML = '<div class="small" style="max-height:200px;overflow-y:auto">' + log.join('<br>') + '</div>';
    resultEl.classList.remove('d-none');
    notify('Restore complete — ' + done + ' project' + (done === 1 ? '' : 's'));
    loadProjectList();
  } catch (err) {
    statusEl.textContent = 'Error: ' + err.message;
    barEl.classList.add('bg-danger');
    notify('Restore error: ' + err.message, 'danger');
  } finally { confirmBtn.disabled = false; restoreZipFile = null; }
});

/* ── Auto-load alignments tab on start ── */
loadProjectList();

document.getElementById('helpBtn').addEventListener('click', function() { helpModal.show(); });
