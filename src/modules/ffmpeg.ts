import { spawn } from 'child_process';

export const ffmpeg = (input: string, output: string): void => {
  const process = spawn('ffmpeg', ['-loglevel', 'error', '-re', '-i', input, '-vcodec', 'copy', '-acodec', 'copy', '-f', 'flv', output]);

  process.stderr.on('data', (data) => {
    console.log(`STDERR: ${data}`);
  });

  process.on('close', (code) => {
    console.log(`Process exited with code ${code}`);
  });
};
