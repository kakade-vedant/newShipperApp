import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import '/constants/colors.dart';
import '/constants/fontSize.dart';
import '/constants/fontWeights.dart';
import '/constants/spaces.dart';
import '/controller/buyGPSboolController.dart';
import '/controller/transporterIdController.dart';
import '/functions/buyGPSApiCalls.dart';
import '/functions/truckApis/getTruckDataWithPageNo.dart';
import '/models/truckModel.dart';
import '/screens/MapPage.dart';
import '/screens/OpenCellId.dart';
import '/screens/historyScreen.dart';
import '/widgets/Header.dart';
// import 'package:flutter_config/flutter_config.dart';
import '/widgets/alertDialog/buyGPSAddTruckDialog.dart';
import '/widgets/alertDialog/nextUpdateAlertDialog.dart';
import '/widgets/buttons/buyGPSRadioButtons.dart';
import '/widgets/buttons/helpButton.dart';
import '/widgets/buyGPSTrucksStack.dart';
import '/widgets/searchLoadWidget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class BuyGpsScreen extends StatefulWidget {
  const BuyGpsScreen({Key? key}) : super(key: key);

  @override
  _BuyGpsScreenState createState() => _BuyGpsScreenState();
}

class _BuyGpsScreenState extends State<BuyGpsScreen> {
  String? _groupValue;
  String? _durationGroupValue;
  TransporterIdController transporterIdController =
      Get.put(TransporterIdController());
  TruckModel truckModel = TruckModel();
  ScrollController scrollController = ScrollController();
  String? truckID;
  var truckDataList = [];
  bool loading = false;
  late List jsonData;
  int i = 0;
  // final String truckApiUrl = FlutterConfig.get('truckApiUrl');
  final String truckApiUrl = dotenv.get('truckApiUrl');

  // final String buyGPSApiUrl = FlutterConfig.get('buyGPSApiUrl');
  final String buyGPSApiUrl = dotenv.get('buyGpsApiUrl');

  BuyGPSApiCalls buyGPSApiCalls = BuyGPSApiCalls();
  Position? _currentPosition;
  String? _currentAddress;
  bool locationPermissionis = false;

  BuyGPSHudController updateButtonController = Get.put(BuyGPSHudController());

  // _onSelected(int index) {
  //   setState(() => _selectedIndex = index);
  // }
  @override
  void initState() {
    super.initState();
    updateButtonController.updateButtonHud(false);
    updateButtonController.updateTruckID(null);
    _getUserAddress();

    setState(() {
      loading = true;
    });

    getTruckData(i);

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        i = i + 1;
        getTruckData(i);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  ValueChanged<String?> _ratevalueChangedHandler() {
    return (value) => setState(() => {
          truckID = updateButtonController.updateTruckID.value,
          _groupValue = value!,
          updateButtonController.updateRadioHud(true),
          if (truckID == "")
            {
              updateButtonController.updateButtonHud(false),
            }
          else
            {
              updateButtonController.updateButtonHud(true),
            }
        });
  }

  ValueChanged<String?> _durationvalueChangedHandler() {
    return (duration) => setState(() => _durationGroupValue = duration!);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        body: Container(
          margin: EdgeInsets.fromLTRB(space_3, space_4, space_3, 0),
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: space_2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Header(reset: false, text: 'Buy GPS', backButton: true),
                        HelpButtonWidget()
                      ],
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.fromLTRB(space_3, 0, space_3, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select Plan",
                                style: TextStyle(
                                    color: veryDarkGrey,
                                    fontSize: size_8,
                                    fontWeight: mediumBoldWeight),
                              ),
                              MyRadioOption<String>(
                                value: '2500',
                                groupValue: _groupValue,
                                duration: '1 year',
                                groupDurationValue: _durationGroupValue,
                                onDurationChanged:
                                    _durationvalueChangedHandler(),
                                onChanged: _ratevalueChangedHandler(),
                                text: '₹2500/ year',
                              ),
                              MyRadioOption<String>(
                                value: '3500',
                                duration: '2 years',
                                groupValue: _groupValue,
                                groupDurationValue: _durationGroupValue,
                                onDurationChanged:
                                    _durationvalueChangedHandler(),
                                onChanged: _ratevalueChangedHandler(),
                                text: '₹3500/ 2 years',
                              ),
                            ],
                          ),
                        ],
                      )),
                  SizedBox(
                    height: space_3,
                  ),
                  Container(
                      margin: EdgeInsets.symmetric(vertical: space_3),
                      child: SearchLoadWidget(
                        hintText: 'Search truck',
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => NextUpdateAlertDialog());
                        },
                      )),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Truck",
                          style: TextStyle(
                              color: bidBackground,
                              fontSize: size_9,
                              fontWeight: mediumBoldWeight),
                        ),
                        GestureDetector(
                            onTap: () => {
                                  showDialog(
                                      context: context,
                                      builder: (context) =>
                                          BuyGPSAddTruckDialog()),
                                  // Get.to(() =>
                                  //     MapPage()
                                  // // HistoryScreen(
                                  // //   // imei: transporterIDImei,
                                  // //   // TruckNo: TruckNo,
                                  // // )
                                  // )
                                },
                            child: Row(
                              children: [
                                Text(
                                  "+",
                                  style: TextStyle(
                                      color: bidBackground,
                                      fontSize: size_9,
                                      fontWeight: mediumBoldWeight),
                                ),
                                Text(
                                  "Add Truck",
                                  style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: bidBackground,
                                      fontSize: size_9,
                                      fontWeight: mediumBoldWeight),
                                ),
                              ],
                            ))
                      ]),
                  BuyGPSTrucksStack(
                      durationGroupValue: _durationGroupValue,
                      locationPermissionis: locationPermissionis,
                      context: context,
                      currentAddress: _currentAddress,
                      groupValue: _groupValue,
                      loading: loading,
                      scrollController: scrollController,
                      truckDataList: truckDataList)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  getTruckData(int i) async {
    var truckDataListForPagei = await getGPSTruckDataWithPageNo(i);
    for (var truckData in truckDataListForPagei) {
      truckDataList.add(truckData);
    }
    setState(() {
      loading = false;
    });
  }

  _getUserAddress() async {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
      });
      try {
        List<Placemark> p = await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude);
        Placemark place = p[0];
        setState(() {
          locationPermissionis = true;
          _currentAddress =
              "${place.locality}, ${place.postalCode}, ${place.country}";
        });
      } catch (e) {
        print(e);
      }
    }).catchError((e) {
      print("Error is $e");
    });
  }
}
