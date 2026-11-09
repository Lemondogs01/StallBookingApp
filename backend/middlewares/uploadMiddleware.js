const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadRoot = path.join(__dirname, '../uploads');
const uploadFolders = new Set(['slips', 'profiles']);
const allowedExtensions = new Set([
  '.jpeg', '.jpg', '.png', '.gif', '.webp', '.heic', '.heif'
]);
const allowedMimeTypes = new Set([
  'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif'
]);

const createUploadMiddleware = (folder) => {
  if (!uploadFolders.has(folder)) {
    throw new Error(`Unsupported upload folder: ${folder}`);
  }

  const uploadDir = path.join(uploadRoot, folder);
  fs.mkdirSync(uploadDir, { recursive: true });

  const storage = multer.diskStorage({
    destination: (_req, _file, callback) => callback(null, uploadDir),
    filename: (_req, file, callback) => {
      const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
      const extension = path.extname(file.originalname).toLowerCase();
      callback(null, `${uniqueSuffix}${extension}`);
    }
  });

  const fileFilter = (_req, file, callback) => {
    const extension = path.extname(file.originalname).toLowerCase();
    const mimeType = file.mimetype.toLowerCase();

    if (allowedExtensions.has(extension) && allowedMimeTypes.has(mimeType)) {
      return callback(null, true);
    }

    const error = new Error(
      'Only JPEG, PNG, GIF, WebP, HEIC, or HEIF images are allowed.'
    );
    error.status = 415;
    callback(error);
  };

  return multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter
  });
};

module.exports = createUploadMiddleware;
