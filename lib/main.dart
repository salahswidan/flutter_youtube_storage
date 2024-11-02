import 'dart:convert';
import 'dart:io';
import 'package:flutter_youtube_storage/play_video.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String accessToken = "";
  List videos = [];
  GoogleSignIn? googleSignIn;
  googleSingIn() async {
    await googleSignIn?.signIn();
    GoogleSignInAuthentication auth =
        await googleSignIn!.currentUser!.authentication;
    setState(() {
      accessToken = auth.accessToken!;
    });
    fetchVideos();
  }

  getVideo() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickVideo(source: ImageSource.gallery);
    if (xFile != null) {
      upLoadVideo(File(xFile.path));
    }
  }

  upLoadVideo(File myVideo) async {
    Map<String, String> authHeader =
        await googleSignIn!.currentUser!.authHeaders;
    IOClient ioClient = IOClient(HttpClient());
    AuthenticatedClient authenticatedClient =
        AuthenticatedClient(ioClient, authHeader);

    YouTubeApi youtubeApi = YouTubeApi(authenticatedClient);

    Video video = Video(
      snippet: VideoSnippet(
        title: "video unListed",
        description: "salah swidan 2",
      ),
      status: VideoStatus(
        privacyStatus: "unlisted",
      ),
    );
    final stream = myVideo.openRead();
    Media media = Media(stream, await myVideo.length());
    // upload video
    await youtubeApi.videos
        .insert(video, ["snippet", "status"], uploadMedia: media);
  }

  fetchVideos() async {
    final channelResponse = await http.get(
      Uri.parse(
          'https://www.googleapis.com/youtube/v3/channels?part=contentDetails&mine=true'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    // my channel details
    var channelData = jsonDecode(channelResponse.body);

    String channelId = channelData["items"][0]["contentDetails"]
        ["relatedPlaylists"]["uploads"];

    final videoResponse = await http.get(
      Uri.parse(
          'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=$channelId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (videoResponse.statusCode == 200) {
      var data = json.decode(videoResponse.body);
      setState(() {
        videos = data["items"];
      });
    } else {
      print("error");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    googleSignIn = GoogleSignIn(scopes: [
      YouTubeApi.youtubeUploadScope, // to can upload videos
      YouTubeApi.youtubeReadonlyScope, // fetch videos from my account
    ]);
    googleSingIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          getVideo();
        },
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) => ListTile(
                  onTap: () {
                    print(videos[index]["snippet"]["resourceId"]["videoId"]);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PlayVideo(
                              videoId: videos[index]["snippet"]["resourceId"]
                                  ["videoId"],
                            )));
                  },
                  // leading: Container(
                  //     height: 120,
                  //     width: 120,
                  //     child: Image.network(videos[index]["snippet"]
                  //         ["thumbnails"]["default"]["url"])),
                  title: Text(videos[index]["snippet"]["title"]),
                  subtitle: Text(videos[index]["snippet"]["description"]),
                )),
      ),
    );
  }
}

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  AuthenticatedClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(_headers));
  }
}
