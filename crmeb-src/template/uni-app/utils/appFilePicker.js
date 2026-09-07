let requestCodeSeed = 61000;
let selecting = false;

function nextRequestCode() {
  requestCodeSeed += 1;
  if (requestCodeSeed > 65000) requestCodeSeed = 61001;
  return requestCodeSeed;
}

function valueToString(value) {
  return value == null ? '' : value.toString();
}

function safeFileName(name) {
  const value = valueToString(name).replace(/\0/g, '').replace(/[\\/:*?"<>|]/g, '').trim();
  return value || `model_${Date.now()}`;
}

function getFileInfo(resolver, uri) {
  const info = { name: '', size: 0 };
  let cursor = null;
  try {
    cursor = plus.android.invoke(
      resolver,
      'query',
      uri,
      null,
      null,
      null,
      null,
    );
    if (cursor) {
      plus.android.importClass(cursor);
      if (cursor.moveToFirst()) {
        const nameIndex = cursor.getColumnIndex('_display_name');
        const sizeIndex = cursor.getColumnIndex('_size');
        if (nameIndex >= 0) info.name = valueToString(cursor.getString(nameIndex));
        if (sizeIndex >= 0) info.size = Number(cursor.getLong(sizeIndex)) || 0;
      }
    }
  } catch (error) {
    console.log('读取文件信息失败', error);
  } finally {
    try {
      if (cursor) cursor.close();
    } catch (error) {}
  }
  return info;
}

function copyUriToCache(activity, resolver, uri, originalName) {
  const File = plus.android.importClass('java.io.File');
  const FileOutputStream = plus.android.importClass('java.io.FileOutputStream');
  const BufferedInputStream = plus.android.importClass('java.io.BufferedInputStream');
  const BufferedOutputStream = plus.android.importClass('java.io.BufferedOutputStream');
  const JavaArray = plus.android.importClass('java.lang.reflect.Array');
  const Byte = plus.android.importClass('java.lang.Byte');
  let input = null;
  let output = null;

  try {
    const cacheRoot = plus.android.invoke(activity, 'getExternalCacheDir') || plus.android.invoke(activity, 'getCacheDir');
    const cacheDir = new File(cacheRoot, 'model_uploads');
    if (!plus.android.invoke(cacheDir, 'exists')) plus.android.invoke(cacheDir, 'mkdirs');

    const target = new File(cacheDir, `${Date.now()}_${safeFileName(originalName)}`);
    const sourceStream = plus.android.invoke(resolver, 'openInputStream', uri);
    if (!sourceStream) throw new Error('无法读取所选文件');

    input = new BufferedInputStream(sourceStream);
    output = new BufferedOutputStream(new FileOutputStream(target));
    const buffer = JavaArray.newInstance(Byte.TYPE, 8192);
    let length = 0;
    while ((length = plus.android.invoke(input, 'read', buffer)) !== -1) {
      plus.android.invoke(output, 'write', buffer, 0, length);
    }
    plus.android.invoke(output, 'flush');
    const absolutePath = valueToString(plus.android.invoke(target, 'getAbsolutePath'));
    return absolutePath ? `file://${absolutePath}` : '';
  } finally {
    try {
      if (output) plus.android.invoke(output, 'close');
    } catch (error) {}
    try {
      if (input) plus.android.invoke(input, 'close');
    } catch (error) {}
  }
}

export function chooseAndroidFile() {
  return new Promise((resolve, reject) => {
    if (typeof plus === 'undefined' || !plus.android || plus.os.name !== 'Android') {
      reject({ msg: '当前设备暂不支持模型文件选择' });
      return;
    }
    if (selecting) {
      reject({ msg: '文件选择器已打开' });
      return;
    }

    selecting = true;
    const requestCode = nextRequestCode();
    const activity = plus.android.runtimeMainActivity();
    const previousActivityResult = activity.onActivityResult;
    const Intent = plus.android.importClass('android.content.Intent');
    const Activity = plus.android.importClass('android.app.Activity');
    const intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);

    const finish = () => {
      selecting = false;
      activity.onActivityResult = previousActivityResult;
    };

    try {
      intent.addCategory(Intent.CATEGORY_OPENABLE);
      intent.setType('*/*');
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
      activity.onActivityResult = (currentRequestCode, resultCode, data) => {
        if (Number(currentRequestCode) !== requestCode) {
          if (typeof previousActivityResult === 'function') {
            previousActivityResult(currentRequestCode, resultCode, data);
          }
          return;
        }

        if (Number(resultCode) !== Number(Activity.RESULT_OK) || !data) {
          finish();
          reject({ cancel: true });
          return;
        }

        const uri = plus.android.invoke(data, 'getData');
        if (!uri) {
          finish();
          reject({ msg: '未获取到所选文件' });
          return;
        }

        setTimeout(() => {
          uni.showLoading({ title: '正在读取文件', mask: true });
          try {
            const resolver = plus.android.invoke(activity, 'getContentResolver');
            const info = getFileInfo(resolver, uri);
            const path = copyUriToCache(activity, resolver, uri, info.name);
            finish();
            uni.hideLoading();
            if (!path) {
              reject({ msg: '文件复制失败' });
              return;
            }
            resolve({ path, name: info.name, size: info.size });
          } catch (error) {
            finish();
            uni.hideLoading();
            console.log('处理模型文件失败', error);
            reject({ msg: '模型文件读取失败' });
          }
        }, 0);
      };
      plus.android.invoke(activity, 'startActivityForResult', intent, requestCode);
    } catch (error) {
      finish();
      console.log('打开系统文件选择器失败', error);
      reject({ msg: '无法打开系统文件选择器' });
    }
  });
}
