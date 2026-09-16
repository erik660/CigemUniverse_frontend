// Ganti isLocal ke true jika ingin mengetes backend yang berjalan di lokal komputer Anda
const bool isLocal = false; 

// Untuk Emulator Android gunakan '10.0.2.2:8000', untuk Web/Chrome gunakan '127.0.0.1:8000'
const String localHost = '127.0.0.1:8000'; 
const String productionHost = 'cigemuniverse.vercel.app';

const String backendHost = isLocal ? localHost : productionHost;

Uri backendApiUri(String path) {
  if (isLocal) {
    return Uri.http(backendHost, path);
  } else {
    return Uri.https(backendHost, path);
  }
}
