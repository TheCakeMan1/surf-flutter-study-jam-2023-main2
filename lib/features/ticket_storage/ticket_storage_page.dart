import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
class ListItem extends StatelessWidget {
  final Function(String) onDownloadPlayPausedPressed;
  final Function(String) onDelete;
  DownloadTask? downloadTask;
  String name = "";
  String url = "";
  late Icon icons;
  String pathPDF = "";

  ListItem(
      {Key? key,
        required this.url,
        required this.pathPDF,
        required this.name,
        required this.icons,
        required this.onDownloadPlayPausedPressed,
        required this.onDelete,
        this.downloadTask})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Row(
                        children: [
                          icons,
                          const SizedBox(width: 10,),
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                        if (downloadTask != null)
                          ValueListenableBuilder(
                              valueListenable: downloadTask!.status,
                              builder: (context, value, child) {
                                return const Text("");
                              }
                          ),
                      ],
                    )),
                downloadTask != null
                    ? ValueListenableBuilder(
                    valueListenable: downloadTask!.status,
                    builder: (context, value, child) {
                      switch (downloadTask!.status.value) {
                        case DownloadStatus.downloading:
                          return IconButton(
                              onPressed: () {
                                onDownloadPlayPausedPressed(url);
                              },
                              icon: const Icon(Icons.pause));
                        case DownloadStatus.paused:
                          return IconButton(
                              onPressed: () {
                                onDownloadPlayPausedPressed(url);
                              },
                              icon: const Icon(Icons.play_arrow));
                        case DownloadStatus.completed:
                          return Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Padding(padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                                  child: IconButton(
                                      onPressed: () {
                                        onDelete(url);
                                      },
                                      icon: const Icon(Icons.delete)),
                                ),
                                Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    child: IconButton(
                                        onPressed: () {
                                          if (pathPDF.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PdfView(path: pathPDF),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.folder_open)),
                                )]);
                        case DownloadStatus.failed:
                        case DownloadStatus.canceled:
                          return IconButton(
                              onPressed: () {
                                onDownloadPlayPausedPressed(url);
                              },
                              icon: const Icon(Icons.download));
                        case DownloadStatus.queued:
                          // TODO: Handle this case.
                          break;
                      }
                      return Text("$value", style: TextStyle(fontSize: 16));
                    })
                    : IconButton(
                    onPressed: () {
                      onDownloadPlayPausedPressed(url);
                    },
                    icon: const Icon(Icons.download))
              ],
            ), // if (widget.item.isDownloadingOrPaused)
            if (downloadTask != null && !downloadTask!.status.value.isCompleted)
              ValueListenableBuilder(
                  valueListenable: downloadTask!.progress,
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: LinearProgressIndicator(
                        value: value,
                        color:
                        downloadTask!.status.value == DownloadStatus.paused
                            ? Colors.grey
                            : Colors.amber,
                      ),
                    );
                  }),
            if (downloadTask != null)
              FutureBuilder<DownloadStatus>(
                  future: downloadTask!.whenDownloadComplete(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DownloadStatus> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return Text(
                            'Загрузка');
                      default:
                        if (snapshot.hasError) {
                          return Text('Ошибка: ${snapshot.error}');
                        } else {
                          if ("${snapshot.data}" == "DownloadStatus.completed"){
                            return Text('Загрузка завершена');
                          }
                          else if ("${snapshot.data}" == "DownloadStatus.failed"){
                            return Text('Произошла ошибка');
                          }
                          return Text('');
                        }
                    }
                  }
              )
          ],
        ),
      ),
    );
  }
}

/// Экран “Хранения билетов”.
class TicketStoragePage extends StatefulWidget {
  const TicketStoragePage({Key? key}) : super(key: key);

  @override
  State<TicketStoragePage> createState() => _TicketStoragePageState();
}

class _TicketStoragePageState extends State<TicketStoragePage> {

  late List<String> _links = [
    'http://www.africau.edu/images/default/sample.pdf',
    'https://journal-free.ru/download/dachnye-sekrety-11-noiabr-2019.pdf',
  ];

  String errors = "";

  static bool isUrlPdfValid(String text){
    final data = text.toLowerCase();
    var isValidUrl = Uri.tryParse(data)?.isAbsolute;
    final hasHttps = data.startsWith('https://');
    final hasPdf = data.endsWith('.pdf');
    return isValidUrl = true && hasHttps && hasPdf ;
  }

  static bool isUrlPdfValids(String text){
    final data = text.toLowerCase();
    var isValidUrl = Uri.tryParse(data)?.isAbsolute;
    final hasHttps = data.startsWith('http://');
    final hasPdf = data.endsWith('.pdf');
    return isValidUrl = true && hasHttps && hasPdf ;
  }

  List<Icon> listIcon = [Icon(Icons.airplanemode_active),Icon(Icons.train)];

  final StreamController<double> _progressStreamController = StreamController<double>();
  String add = "";
  var downloadManager = DownloadManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Хранение билетов",
            style: TextStyle(color: Colors.black)
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: StreamBuilder<double>(
              stream: _progressStreamController.stream,
              initialData: 0.0,
              builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
                return ListView.builder(
                  itemCount: _links.length,
                  itemBuilder: (context, index) {
                    return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListItem(
                            onDownloadPlayPausedPressed: (url) async {
                              setState(() {
                                var task = downloadManager.getDownload(url);

                                if (task != null && !task.status.value.isCompleted) {
                                  switch (task.status.value) {
                                    case DownloadStatus.downloading:
                                      downloadManager.pauseDownload(url);
                                      break;
                                    case DownloadStatus.paused:
                                      downloadManager.resumeDownload(url);
                                      break;
                                    case DownloadStatus.queued:
                                      // TODO: Handle this case.
                                      break;
                                    case DownloadStatus.completed:
                                      // TODO: Handle this case.
                                      break;
                                    case DownloadStatus.failed:
                                      // TODO: Handle this case.
                                      break;
                                    case DownloadStatus.canceled:
                                      // TODO: Handle this case.
                                      break;
                                  }
                                } else {
                                  downloadManager.addDownload(url,
                                      "/storage/emulated/0/Download/${downloadManager.getFileNameFromUrl(url)}");
                                }
                              });
                            },
                            onDelete: (url) {
                              var fileName =
                                  "/storage/emulated/0/Download/${downloadManager.getFileNameFromUrl(url)}";
                              var file = File(fileName);
                              file.delete();

                              downloadManager.removeDownload(url);
                              setState(() {});
                            },
                            url: _links[index],
                            downloadTask: downloadManager.getDownload(_links[index]), name: 'Ticket ${index+1}', icons: listIcon[index], pathPDF: '/storage/emulated/0/Download/${downloadManager.getFileNameFromUrl(_links[index])}',),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
            FloatingActionButton.extended(
              backgroundColor: Colors.white,
              onPressed: (){
                showDialog(context: context, builder: (BuildContext context){
                  return AlertDialog(
                      title: const Text("Добавление билета"),
                      content: SizedBox(
                      height: 70,
                          child: Column(
                        children: [
                          TextField(
                              onChanged: (String value) {
                                setState(() {
                                  add = value;
                                  errors = "";
                                });
                              }
                          ),
                          Text(errors, style: const TextStyle(color: Colors.red),),
                        ],
                      )),
                      actions: [
                        ElevatedButton(
                          onPressed: (){
                            if(isUrlPdfValid(add) || isUrlPdfValids(add)){
                              setState(() {
                                errors = "";
                                _links.add(add);
                                listIcon.add(const Icon(Icons.train_outlined));
                                Navigator.of(context).pop();
                              });
                            }
                            else{
                              setState(() {
                                errors = "Неверный адрес!";
                              });
                            }
                          },
                          child: const Icon(Icons.train_outlined),
                        ),
                        const SizedBox(width: 5,),
                        ElevatedButton(
                          onPressed: (){
                            if(isUrlPdfValid(add) || isUrlPdfValids(add)){
                              setState(() {
                                errors = "";
                                _links.add(add);
                                listIcon.add(const Icon(Icons.airplanemode_active));
                                Navigator.of(context).pop();
                              });
                            }
                            else{
                              setState(() {
                                errors = "Неверный адрес!";
                              });
                            }

                          },
                          child: const Icon(Icons.airplanemode_active),
                        ),
                        const SizedBox(width: 5,),
                        ElevatedButton(
                          onPressed: (){
                            if(isUrlPdfValid(add) || isUrlPdfValids(add)) {
                              setState(() {
                                errors = "";
                                _links.add(add);
                                listIcon.add(const Icon(Icons.directions_bus));
                                Navigator.of(context).pop();
                              });
                            }
                            else{
                              setState(() {
                                errors = "Неверный адрес!";
                              });
                            }
                          },
                          child: const Icon(Icons.directions_bus),
                        ),
                        const SizedBox(width: 5,),
                      ],
                  );
                });
              },
              label: const Text(
                "Добавить",
                style: TextStyle(color: Colors.black),
              ),
            )
    );
  }

  @override
  void dispose() {
    _progressStreamController.close();
    super.dispose();
  }
}
