const fs = require('node:fs/promises');

const removeUploadedFile = async (file) => {
  if (!file?.path) return;

  try {
    await fs.unlink(file.path);
  } catch (error) {
    if (error.code !== 'ENOENT') {
      console.error('Failed to remove an unreferenced upload:', error.message);
    }
  }
};

module.exports = removeUploadedFile;
