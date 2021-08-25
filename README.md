# RTSP to HLS transcoding server

### How to run

```shell
make docker-compose
```

### Usage

Usage example for [axios](https://github.com/axios/axios)

```javascript
// Link to RTSP stream
const link = 'rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov';
const rtsp = encodeURIComponent(link);

const res = await axios({ 
  method: 'GET',
  url: 'http://localhost:8000/stream',
  params: { rtsp }
});

const file = res.data.file; // .m3u8 filename
// You can access .m3u8 file on http://localhost:8080/live/<.m3u8 filename>
```


http://172.16.240.31:8000/stream?rtsp=rtsp://admin:a12345678@192.168.31.8:554

docker run --name rtsp2hls -p 8080:8080 -p 8000:8000 -d docker.io/xyz27900/rtsp2hls
