import 'package:web_socket_channel/io.dart';

class FlutterImSdk{

  getChannel(String imAddress){
    return IOWebSocketChannel.connect(Uri.parse(imAddress));
  }
}