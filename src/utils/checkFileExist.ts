import fs from 'fs';
import path from 'path';

export const checkFileExist = (filePath: string, timeout: number): Promise<boolean> =>
  new Promise(resolve => {
    const dir = path.dirname(filePath);
    const basename = path.basename(filePath);

    const watcher = fs.watch(dir, (event, filename) => {
      if (event === 'rename' && filename === basename) {
        clearTimeout(timer);
        watcher.close();
        resolve(true);
      }
    });

    fs.access(filePath, fs.constants.R_OK, err => {
      if (!err) {
        clearTimeout(timer);
        watcher.close();
        resolve(true);
      }
    });

    const timer = setTimeout(() => {
      watcher.close();
      resolve(false);
    }, timeout);
  });
