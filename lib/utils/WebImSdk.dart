import 'package:web_socket_channel/html.dart';

class FlutterImSdk{

  getChannel(String imAddress){
    return HtmlWebSocketChannel.connect(Uri.parse(imAddress));
  }
}