'use strict';

const ALIGN_API = '/exist/apps/discept-sync/src/api/alignments.xql';
const SESSION_KEY = 'ks-active-project';

let currentTEI = '';
let currentProject = null;
let previewingVersion = null;
let previewXml = '';
let restoreZipFile = null;

/* Active session: project loaded from discept-sync into DiScEPT */
let activeSession = localStorage.getItem(SESSION_KEY) || null;

/* ── Bootstrap instances ── */
const syncConfigModal = new bootstrap.Modal('#syncConfigModal');
const saveAlignModal = new bootstrap.Modal('#saveAlignModal');
const restoreModal = new bootstrap.Modal('#restoreModal');
const helpModal = new bootstrap.Modal('#helpModal');
const toastEl = document.getElementById('toast');
const bsToast = new bootstrap.Toast(toastEl, { delay: 3500 });

/* ── Utilities ── */
function notify(msg, type) {
  toastEl.className = 'toast align-items-center text-white border-0 bg-' + (type || 'success');
  document.getElementById('toastMsg').textContent = msg;
  bsToast.show();
}
function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
function enc(s) { return encodeURIComponent(s); }

function addLineNumbers(text) {
  return text.split('\n').map(function (l) {
    return '<span>' + l.replace(/</g, '&lt;').replace(/>/g, '&gt;') + '</span>';
  }).join('');
}

function fmtTs(ts) {
  if (!ts || ts.length < 15) return ts || '—';
  return ts.slice(6, 8) + '/' + ts.slice(4, 6) + '/' + ts.slice(0, 4)
    + ' ' + ts.slice(9, 11) + ':' + ts.slice(11, 13) + ':' + ts.slice(13, 15);
}

function dlBlob(content, filename, mime) {
  var url = URL.createObjectURL(new Blob([content], { type: mime || 'application/xml' }));
  var a = document.createElement('a');
  a.href = url; a.download = filename; a.style.display = 'none';
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

/* ── Active session banner ── */
function updateSessionBanner() {
  var wrap = document.getElementById('activeSessionWrap');
  var nameEl = document.getElementById('activeSessionName');
  if (activeSession) {
    wrap.classList.remove('d-none');
    nameEl.textContent = activeSession;
  } else {
    wrap.classList.add('d-none');
  }
}

function setActiveSession(name) {
  activeSession = name;
  if (name) localStorage.setItem(SESSION_KEY, name);
  else localStorage.removeItem(SESSION_KEY);
  updateSessionBanner();
}

document.getElementById('clearSessionBtn').addEventListener('click', function () {
  setActiveSession(null);
  notify('Session cleared', 'secondary');
});

/* ── Tabs ── */
var syncGroup = document.getElementById('syncGroup');
var downloadBtn = document.getElementById('downloadBtn');
var saveAlignBtn = document.getElementById('saveAlignBtn');

document.getElementById('mainTabs').addEventListener('click', function (e) {
  var link = e.target.closest('[data-tab]');
  if (!link) return;
  e.preventDefault();
  var tab = link.dataset.tab;
  document.querySelectorAll('.tab-pane-content').forEach(function (p) { p.classList.add('d-none'); });
  document.getElementById('pane-' + tab).classList.remove('d-none');
  document.querySelectorAll('#mainTabs .nav-link').forEach(function (l) { l.classList.remove('active'); });
  link.classList.add('active');
  var isConversion = tab === 'conversion';
  syncGroup.classList.toggle('d-none', !isConversion);
  downloadBtn.classList.toggle('d-none', !isConversion);
  saveAlignBtn.classList.toggle('d-none', isConversion);
  if (!isConversion) loadProjectList();
});

/* ── Conversion ── */
var defaultConfig = {
  resourceUrl: 'https://existdb2.websoupcloud.it/exist/apps/discept/data/annoParsed.xml',
  username: '', password: '', proxyUrl: ''
};
var currentConfig = Object.assign({}, defaultConfig);

function loadConfigForm(cfg) {
  cfg = cfg || defaultConfig;
  document.getElementById('resourceUrl').value = cfg.resourceUrl;
  document.getElementById('username').value = cfg.username;
  document.getElementById('password').value = cfg.password;
  document.getElementById('proxyUrl').value = cfg.proxyUrl || '';
}

async function convertFile(file) {
  if (!file) return;
  document.querySelector('#sourceContent code').innerHTML = addLineNumbers(await file.text());
  var fd = new FormData(); fd.append('file', file);
  try {
    var r = await fetch('/exist/apps/discept-sync/src/api/transform.xql', { method: 'POST', body: fd });
    if (!r.ok) throw new Error('Server error: ' + r.status);
    currentTEI = await r.text();
    document.querySelector('#convertedContent code').innerHTML = addLineNumbers(currentTEI);
  } catch (e) { notify('Conversion failed: ' + e.message, 'danger'); }
}

document.getElementById('sourceFile').addEventListener('change', function (e) { convertFile(e.target.files[0]); });
downloadBtn.addEventListener('click', function () { if (currentTEI) dlBlob(currentTEI, 'converted.xml'); });
document.getElementById('configureSync').addEventListener('click', function (e) {
  e.preventDefault(); loadConfigForm(currentConfig); syncConfigModal.show();
});
document.getElementById('resetConfig').addEventListener('click', function () { loadConfigForm(defaultConfig); });
document.getElementById('saveConfig').addEventListener('click', function () {
  var f = document.getElementById('syncConfigForm');
  currentConfig = {
    resourceUrl: f.resourceUrl.value, username: f.username.value,
    password: f.password.value, proxyUrl: f.proxyUrl.value
  };
  syncConfigModal.hide(); notify('Configuration saved');
});
document.getElementById('syncBtn').addEventListener('click', async function () {
  try {
    var target = currentConfig.proxyUrl
      ? currentConfig.proxyUrl + '?url=' + enc(currentConfig.resourceUrl)
      : currentConfig.resourceUrl;
    document.querySelector('#convertedContent code').innerHTML = addLineNumbers(await (await fetch(target)).text());
    notify('Sync complete');
  } catch (e) { notify(e.message, 'danger'); }
});

/* ══════════════════════════════════════════
   ALIGNMENTS
   ══════════════════════════════════════════ */

async function loadProjectList() {
  var list = document.getElementById('projectList');
  list.innerHTML = '<div class="ks-empty-state"><i class="bi bi-hourglass-split"></i>Loading…</div>';
  try {
    var projects = await (await fetch(ALIGN_API + '?action=list')).json();

    /* update save modal select */
    var sel = document.getElementById('saveProjectSelect');
    var prev = sel.value;
    sel.innerHTML = '<option value="">— select project —</option>';
    projects.forEach(function (p) {
      var o = document.createElement('option'); o.value = p.name; o.textContent = p.name; sel.appendChild(o);
    });
    if (prev) sel.value = prev;

    if (!projects.length) {
      list.innerHTML = '<div class="ks-empty-state"><i class="bi bi-folder-x"></i>No projects yet.<br><span class="small">Create one using the field above.</span></div>';
      return;
    }

    list.innerHTML = '';
    projects.forEach(function (p) {
      var isActive = currentProject && currentProject.name === p.name;
      var isSession = activeSession && activeSession === p.name;
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'list-group-item list-group-item-action' + (isActive ? ' active' : '');
      btn.dataset.project = p.name;

      var sessionBadge = isSession
        ? '<span class="badge ks-session ms-1"><i class="bi bi-link-45deg"></i> session</span>' : '';
      var vBadge = '<span class="badge bg-secondary ms-1" style="font-size:.68rem">' + p.versions + 'v</span>';
      var alnBadge = '<span class="badge bg-light text-dark border ms-1" style="font-size:.68rem">' + p.alignments + ' aln</span>';

      btn.innerHTML =
        '<div class="d-flex justify-content-between align-items-center">' +
        '<div class="text-truncate me-2">' +
        '<span class="fw-semibold">' + esc(p.name) + '</span>' + sessionBadge +
        '<div class="text-muted small">' + esc(p.langs || '—') + '</div>' +
        '</div>' +
        '<div class="text-end">' + alnBadge + vBadge + '</div>' +
        '</div>';

      btn.addEventListener('click', function () { selectProject(p); });
      list.appendChild(btn);
    });
  } catch (e) {
    list.innerHTML = '<div class="text-danger small p-3">Error: ' + esc(e.message) + '</div>';
  }
}

async function selectProject(p) {
  currentProject = p; previewingVersion = null; previewXml = '';
  document.getElementById('alignEmpty').classList.add('d-none');
  document.getElementById('alignDetail').classList.remove('d-none');
  document.getElementById('detailTitle').textContent = p.name;
  document.getElementById('detailMeta').textContent =
    p.alignments + ' alignment' + (p.alignments === 1 ? '' : 's') +
    ' · ' + (p.langs || '—') +
    ' · ' + p.versions + ' version' + (p.versions === 1 ? '' : 's');
  document.querySelectorAll('#projectList .list-group-item').forEach(function (el) {
    el.classList.toggle('active', el.dataset.project === p.name);
  });
  await Promise.all([loadVersionList(p.name), loadCurrentPreview(p.name)]);
}

async function loadVersionList(projectName) {
  var list = document.getElementById('versionList');
  list.innerHTML = '<div class="ks-empty-state"><i class="bi bi-hourglass-split"></i>Loading…</div>';
  try {
    var versions = await (await fetch(ALIGN_API + '?action=versions&project=' + enc(projectName))).json();
    if (!versions.length) {
      list.innerHTML = '<div class="ks-empty-state"><i class="bi bi-inbox"></i>No versions saved yet.</div>';
      return;
    }
    list.innerHTML = '';
    versions.forEach(function (v, i) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'list-group-item list-group-item-action';
      btn.dataset.vfile = v.file;

      /* mark the version that matches the active session load — not trivially knowable,
         so we just mark index 0 as latest */
      var latestBadge = i === 0
        ? '<span class="badge ks-latest ms-1">latest</span>' : '';

      btn.innerHTML =
        '<div class="d-flex justify-content-between align-items-center">' +
        '<div>' +
        '<div class="fw-semibold" style="font-size:.82rem">' + fmtTs(v.timestamp) + latestBadge + '</div>' +
        '<div class="text-muted" style="font-size:.74rem">' + (v.size / 1024).toFixed(1) + ' KB</div>' +
        '</div>' +
        '<i class="bi bi-chevron-right text-muted"></i>' +
        '</div>';

      btn.addEventListener('click', function () { loadVersionPreview(projectName, v.file, btn); });
      list.appendChild(btn);
    });
  } catch (e) {
    list.innerHTML = '<div class="text-danger small p-3">Error: ' + esc(e.message) + '</div>';
  }
}

async function loadCurrentPreview(projectName) {
  document.getElementById('previewLabel').textContent = 'Current version';
  document.getElementById('restoreVersionBtn').classList.add('d-none');
  previewingVersion = null;
  try {
    var r = await fetch(ALIGN_API + '?action=get&project=' + enc(projectName));
    if (!r.ok) {
      document.querySelector('#previewContent code').innerHTML =
        '<span class="text-muted">No file saved yet for this project.</span>';
      return;
    }
    previewXml = await r.text();
    document.querySelector('#previewContent code').innerHTML = addLineNumbers(previewXml);
  } catch (e) {
    document.querySelector('#previewContent code').textContent = 'Error: ' + e.message;
  }
}

async function loadVersionPreview(projectName, vfile, btnEl) {
  document.querySelectorAll('#versionList .list-group-item').forEach(function (el) { el.classList.remove('active'); });
  btnEl.classList.add('active');
  var ts = vfile.replace(/^.+_(\d{8}T\d{6})\.xml$/, '$1');
  document.getElementById('previewLabel').textContent = 'Version ' + fmtTs(ts);
  document.getElementById('restoreVersionBtn').classList.remove('d-none');
  previewingVersion = vfile;
  try {
    previewXml = await (await fetch(
      ALIGN_API + '?action=get-version&project=' + enc(projectName) + '&version=' + enc(vfile)
    )).text();
    document.querySelector('#previewContent code').innerHTML = addLineNumbers(previewXml);
  } catch (e) {
    document.querySelector('#previewContent code').textContent = 'Error: ' + e.message;
  }
}

/* ── Actions ── */
document.getElementById('newProjectBtn').addEventListener('click', function () {
  var name = document.getElementById('newProjectName').value.trim();
  if (!name) return;
  document.getElementById('newProjectName').value = '';
  var sel = document.getElementById('saveProjectSelect');
  if (![].slice.call(sel.options).some(function (o) { return o.value === name; })) {
    var o = document.createElement('option'); o.value = name; o.textContent = name; sel.appendChild(o);
  }
  sel.value = name;
  currentProject = { name: name, alignments: 0, langs: '—', versions: 0 };
  document.getElementById('alignEmpty').classList.add('d-none');
  document.getElementById('alignDetail').classList.remove('d-none');
  document.getElementById('detailTitle').textContent = name;
  document.getElementById('detailMeta').textContent = 'New project — save the first TEI file to begin';
  document.getElementById('versionList').innerHTML =
    '<div class="ks-empty-state"><i class="bi bi-inbox"></i>No versions saved yet.</div>';
  document.querySelector('#previewContent code').innerHTML =
    '<span class="text-muted">Save the first file to begin.</span>';
  saveAlignModal.show();
});

document.getElementById('refreshListBtn').addEventListener('click', loadProjectList);

document.getElementById('downloadCurrentBtn').addEventListener('click', async function () {
  if (!currentProject) return;
  try {
    dlBlob(await (await fetch(ALIGN_API + '?action=get&project=' + enc(currentProject.name))).text(),
      currentProject.name + '.xml');
  } catch (e) { notify('Download error: ' + e.message, 'danger'); }
});

document.getElementById('downloadVersionBtn').addEventListener('click', function () {
  if (!previewXml) return;
  dlBlob(previewXml, previewingVersion || ((currentProject ? currentProject.name : 'export') + '.xml'));
});

document.getElementById('restoreVersionBtn').addEventListener('click', async function () {
  if (!currentProject || !previewingVersion || !previewXml) return;
  if (!confirm('Restore this version as current for "' + currentProject.name + '"?\nA new history entry will be created.')) return;
  try {
    var r = await fetch(ALIGN_API + '?action=save&project=' + enc(currentProject.name),
      { method: 'POST', body: previewXml, headers: { 'Content-Type': 'application/xml' } });
    var j = await r.json();
    if (r.ok) {
      notify('Version restored (' + fmtTs(j.timestamp) + ')');
      selectProject(Object.assign({}, currentProject, { versions: currentProject.versions + 1 }));
    } else { notify(j.error || 'Error', 'danger'); }
  } catch (e) { notify(e.message, 'danger'); }
});

document.getElementById('deleteProjectBtn').addEventListener('click', async function () {
  if (!currentProject) return;
  if (!confirm('Permanently delete "' + currentProject.name + '" and all its versions?\nThis cannot be undone.')) return;
  try {
    var r = await fetch(ALIGN_API + '?action=delete&project=' + enc(currentProject.name), { method: 'DELETE' });
    var j = await r.json();
    if (r.ok) {
      if (activeSession === currentProject.name) setActiveSession(null);
      notify('Project deleted');
      currentProject = null;
      document.getElementById('alignDetail').classList.add('d-none');
      document.getElementById('alignEmpty').classList.remove('d-none');
      loadProjectList();
    } else { notify(j.error || 'Error', 'danger'); }
  } catch (e) { notify(e.message, 'danger'); }
});

/* ── Save alignment modal ── */
saveAlignBtn.addEventListener('click', function () {
  if (currentProject) document.getElementById('saveProjectSelect').value = currentProject.name;
  saveAlignModal.show();
});
document.getElementById('saveAlignFile').addEventListener('change', async function (e) {
  var f = e.target.files[0];
  if (f) document.getElementById('saveAlignXml').value = await f.text();
});
document.getElementById('confirmSaveAlign').addEventListener('click', async function () {
  var projectName = document.getElementById('saveProjectSelect').value;
  var xml = document.getElementById('saveAlignXml').value.trim();
  if (!projectName) { notify('Select a project', 'warning'); return; }
  if (!xml) { notify('No XML content to save', 'warning'); return; }
  try {
    var r = await fetch(ALIGN_API + '?action=save&project=' + enc(projectName),
      { method: 'POST', body: xml, headers: { 'Content-Type': 'application/xml' } });
    var j = await r.json();
    if (r.ok) {
      notify('Saved: version ' + fmtTs(j.timestamp) + ' (' + j.alignments + ' alignments)');
      saveAlignModal.hide();
      document.getElementById('saveAlignXml').value = '';
      document.getElementById('saveAlignFile').value = '';
      await loadProjectList();
      selectProject({
        name: projectName, alignments: j.alignments, langs: '—',
        versions: (currentProject ? currentProject.versions : 0) + 1
      });
    } else { notify(j.error || 'Save error', 'danger'); }
  } catch (e) { notify(e.message, 'danger'); }
});

/* ══════════════════════════════════════════
   BACKUP
   ══════════════════════════════════════════ */
document.getElementById('backupBtn').addEventListener('click', async function () {
  notify('Building backup…', 'secondary');
  try {
    var projects = await (await fetch(ALIGN_API + '?action=list')).json();
    if (!projects.length) { notify('No projects to back up', 'warning'); return; }
    var zip = new JSZip();
    for (var i = 0; i < projects.length; i++) {
      var p = projects[i];
      var folder = zip.folder(p.name);
      var cr = await fetch(ALIGN_API + '?action=get&project=' + enc(p.name));
      if (cr.ok) folder.file('current.xml', await cr.text());
      var versions = await (await fetch(ALIGN_API + '?action=versions&project=' + enc(p.name))).json();
      var vf = folder.folder('versions');
      for (var j = 0; j < versions.length; j++) {
        var vr = await fetch(ALIGN_API + '?action=get-version&project=' + enc(p.name) + '&version=' + enc(versions[j].file));
        if (vr.ok) vf.file(versions[j].file, await vr.text());
      }
    }
    var blob = await zip.generateAsync({ type: 'blob', compression: 'DEFLATE' });
    var ts = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 15);
    dlBlob(blob, 'discept-sync-' + ts + '.zip', 'application/zip');
    notify('Backup complete — ' + projects.length + ' project' + (projects.length === 1 ? '' : 's'));
  } catch (e) { notify('Backup error: ' + e.message, 'danger'); }
});

/* ══════════════════════════════════════════
   RESTORE
   ══════════════════════════════════════════ */
document.getElementById('restoreBtn').addEventListener('click', function () {
  document.getElementById('restoreFile').click();
});
document.getElementById('restoreFile').addEventListener('change', function (e) {
  var file = e.target.files[0]; if (!file) return;
  restoreZipFile = file;
  document.getElementById('restoreProgress').classList.add('d-none');
  document.getElementById('restoreResult').classList.add('d-none');
  document.getElementById('restoreResult').innerHTML = '';
  restoreModal.show();
  e.target.value = '';
});
document.getElementById('confirmRestore').addEventListener('click', async function () {
  if (!restoreZipFile) return;
  var progressEl = document.getElementById('restoreProgress');
  var barEl = document.getElementById('restoreBar');
  var statusEl = document.getElementById('restoreStatus');
  var resultEl = document.getElementById('restoreResult');
  var confirmBtn = document.getElementById('confirmRestore');
  progressEl.classList.remove('d-none'); resultEl.classList.add('d-none');
  confirmBtn.disabled = true;
  var log = []; var done = 0;
  try {
    var zip = await JSZip.loadAsync(restoreZipFile);
    var projectFolders = Object.keys(zip.files)
      .filter(function (p) { return zip.files[p].dir; })
      .map(function (p) { return p.replace(/\/$/, ''); })
      .filter(function (p) { return p.indexOf('/') === -1; });
    var total = projectFolders.length;
    for (var i = 0; i < projectFolders.length; i++) {
      var pName = projectFolders[i];
      statusEl.textContent = 'Restoring "' + pName + '"…';
      barEl.style.width = Math.round((done / total) * 100) + '%';
      var vFiles = Object.keys(zip.files)
        .filter(function (p) { return p.indexOf(pName + '/versions/') === 0 && !zip.files[p].dir && p.slice(-4) === '.xml'; })
        .sort();
      for (var j = 0; j < vFiles.length; j++) {
        var xml = await zip.files[vFiles[j]].async('string');
        var fname = vFiles[j].split('/').pop();
        var ts = fname.replace(/^.+_(\d{8}T\d{6})\.xml$/, '$1');
        var r = await fetch(ALIGN_API + '?action=save&project=' + enc(pName),
          { method: 'POST', body: xml, headers: { 'Content-Type': 'application/xml' } });
        var jr = await r.json();
        log.push((r.ok ? '<span class="text-success">&#10003;</span>' : '<span class="text-danger">&#10007;</span>') +
          ' ' + esc(pName) + ' &mdash; ' + fmtTs(ts) + (r.ok ? '' : ': ' + esc(jr.error || 'error')));
      }
      var currentPath = pName + '/current.xml';
      if (!vFiles.length && zip.files[currentPath]) {
        var xml = await zip.files[currentPath].async('string');
        var r = await fetch(ALIGN_API + '?action=save&project=' + enc(pName),
          { method: 'POST', body: xml, headers: { 'Content-Type': 'application/xml' } });
        var jr = await r.json();
        log.push((r.ok ? '<span class="text-success">&#10003;</span>'
          : '<span class="text-danger">&#10007;</span>') +
          ' ' + esc(pName) + ' (current)' + (r.ok ? '' : ': ' + esc(jr.error || 'error')));
      }
      done++;
      barEl.style.width = Math.round((done / total) * 100) + '%';
    }
    statusEl.textContent = 'Done.';
    barEl.classList.add('bg-success');
    resultEl.innerHTML = '<div class="small border rounded p-2 mt-2" style="max-height:180px;overflow-y:auto">' + log.join('<br>') + '</div>';
    resultEl.classList.remove('d-none');
    notify('Restore complete — ' + done + ' project' + (done === 1 ? '' : 's'));
    loadProjectList();
  } catch (e) {
    statusEl.textContent = 'Error: ' + e.message;
    barEl.classList.add('bg-danger');
    notify('Restore error: ' + e.message, 'danger');
  } finally { confirmBtn.disabled = false; restoreZipFile = null; }
});

/* ══════════════════════════════════════════
   HELP — copy buttons
   ══════════════════════════════════════════ */
document.querySelectorAll('.ks-copy-btn[data-copy]').forEach(function (btn) {
  btn.addEventListener('click', function () {
    var el = document.getElementById(btn.dataset.copy);
    if (!el) return;
    navigator.clipboard.writeText(el.textContent.trim()).then(function () {
      btn.classList.add('copied');
      btn.innerHTML = '<i class="bi bi-clipboard-check"></i>';
      setTimeout(function () {
        btn.classList.remove('copied');
        btn.innerHTML = '<i class="bi bi-clipboard"></i>';
      }, 1800);
    });
  });
});

document.getElementById('helpBtn').addEventListener('click', function () { helpModal.show(); });

/* ── Init ── */
updateSessionBanner();
loadProjectList();
