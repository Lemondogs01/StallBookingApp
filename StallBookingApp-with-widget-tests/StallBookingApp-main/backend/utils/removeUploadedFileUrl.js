const path = require('node:path');
const removeUploadedFile = require('./removeUploadedFile');

const uploadFolders = new Set(['slips', 'profiles']);

const removeUploadedFileUrl = async (url, folder) => {
  if (typeof url !== 'string' || !uploadFolders.has(folder)) return;

  const prefix = `/uploads/${folder}/`;
  if (!url.startsWith(prefix)) return;

  const filename = url.slice(prefix.length);
  if (!filename || path.basename(filename) !== filename) return;

  await removeUploadedFile({
    path: path.join(__dirname, '../uploads', folder, filename),
  });
};

module.exports = removeUploadedFileUrl;
