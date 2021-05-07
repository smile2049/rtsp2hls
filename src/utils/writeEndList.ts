import fs from 'fs';
import path from 'path';

import { EXT_X_ENDLIST } from '@/config';

export const writeEndList = (filePath: string): void => {
  const basename = path.basename(filePath);

  fs.appendFile(filePath, EXT_X_ENDLIST, err => {
    if (err) {
      console.log(`Error during adding ${EXT_X_ENDLIST} to ${basename}`);
    } else {
      console.log(`${EXT_X_ENDLIST} successfully added to ${basename}`);
    }
  });
};
