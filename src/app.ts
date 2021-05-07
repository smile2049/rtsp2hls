import * as fs from 'fs';

import express from 'express';
import md5 from 'md5';

import { HLS_PATH, RTMP_SERVICE_URL } from '@/config';
import { ffmpeg } from '@/modules/ffmpeg';
import { checkFileExist } from '@/utils/checkFileExist';
import { writeEndList } from '@/utils/writeEndList';

const app = express();

app.get('/stream', async (req, res) => {
  const { rtsp } = req.query;

  console.log(`Received new rtsp ${rtsp}`);

  if (typeof rtsp !== 'string' || !rtsp.length) {
    res.sendStatus(400);
    return;
  }

  const hash = md5(rtsp);
  const file = `${hash}.m3u8`;
  const filePath = `${HLS_PATH}/${file}`;

  if (fs.existsSync(filePath)) {
    console.log(`File ${file} already exists`);
    res.send({ file });
    return;
  }

  ffmpeg(rtsp, `${RTMP_SERVICE_URL}/${hash}`, error => {
    if (error) {
      console.error(error.data);
    } else {
      writeEndList(filePath);
    }
  });

  const isCreated = await checkFileExist(filePath, 30000);

  if (isCreated) {
    console.log(`Streaming ${file}`);
    res.send({ file });
  } else {
    console.log(`File ${file} was not created`);
    res.sendStatus(500);
  }
});

app.get('/ping', (req, res) => {
  res.send('pong');
});

app.use((req, res) => {
  res.sendStatus(404);
});

app.listen(8000, () => {
  console.log('Server started');
});

