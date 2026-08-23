import 'package:bam_bam_user/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivcyPolicyScreen extends StatelessWidget {
  const PrivcyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle heroTitleStyle = const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0B1727));
    TextStyle heroSubtitleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF5E6E82));
    TextStyle headingStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF5A00));
    TextStyle contentStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF5E6E82), height: 1.6);
    TextStyle bulletStyle = contentStyle;

    Widget bulletPoint(String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: Dimens.six),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ", style: headingStyle),
            Expanded(child: Text(text, style: bulletStyle)),
          ],
        ),
      );
    }

    return GetBuilder<ProfileController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF2ED),
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "",
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Privacy Policy", style: heroTitleStyle, textAlign: TextAlign.center),
                      Dimens.boxHeight12,
                      Text(
                        "At BamBam, your privacy matters as much as your journey. This policy explains how we collect, use, and protect your personal information every time you ride with us.",
                        style: heroSubtitleStyle,
                        textAlign: TextAlign.center,
                      ),
                      Dimens.boxHeight30,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: Image.asset(
                          'assets/images/terms_bg.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content Section
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFD),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "These terms and conditions (\"Agreement\") constitute a legal agreement between you (\"User\" or \"You\") and Wheels and Wings Global Services Pvt Ltd, operating under the brand name \" Bam Bam Cabs.\" By accessing or using the Bam Bam Cabs website or mobile application (collectively referred to as \"Service\"), you agree to comply with and be bound by the following terms and conditions. Please read these terms carefully before using our Service.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("Collecting data and its usage", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "You have to provide us the below mentioned data when prompted. This may include your personal/confidential information which is for lawful purpose connected with our Services and necessary to be collected by us for such purpose. This may be collected through various inputs and in various places through the Services, including account registration forms, contact us forms, or when you otherwise interact with us. When you register with us to use our Services, you create a user profile.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight12,
                      bulletPoint("Mobile phone Number with country code"),
                      bulletPoint("Email"),
                      bulletPoint("Name"),
                      bulletPoint("Complete Address"),
                      bulletPoint("Date of Birth"),
                      bulletPoint("Gender"),
                      bulletPoint("Password"),
                      bulletPoint("Profile Picture"),
                      Dimens.boxHeight24,

                      Text("Collecting information for usage and accessing our services", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "For collecting any confidential/personal Information or other information that we ask you to submit to us, we use several of technologies that automatically (or passively) collect certain information whenever you visit or interact with the Services (“Usage Information”). This Usage Information may include the browser that you are using, the URL that referred you to our Services, all of the areas within our Services that you visit, and the time of day, among other information. Also, if you choose to disable cookies or flash cookies on your Device, some features of the Services may not function properly or may not be able to customize the delivery of information to you. We cannot control the use of cookies (or the resulting information) by third parties, and use of third party cookies is not covered by our Privacy Policy.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("Information third parties provide about you", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "We may, from time to time, supplement the information we collect about you through our website or Mobile Application or Services with outside records from third parties.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("Our Mobile app collecting your information", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "We provide all of our services through our Mobile Application. We may collect and use your technical data and related information, including but not limited to, technical information about your device, system and application software, and peripherals, that is gathered periodically to facilitate the provision of software updates, product support and other services to you (if any) related to such Mobile Applications.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight8,
                      Text(
                        "When you use any of our Mobile Applications, the Mobile Application may automatically collect and store some or all of the following information from your mobile device (“Mobile Device Information”), in addition to the Device Information, including without limitation:",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight12,
                      bulletPoint("Language and country location (if applicable)"),
                      bulletPoint("The make and model of your mobile Device"),
                      bulletPoint("Your mobile operating system"),
                      bulletPoint("The type of mobile internet browsers you are using"),
                      bulletPoint("Your GPS/Demographic location"),
                      bulletPoint("Information about how you interact with the Mobile Application and any of our web sites to which the Mobile Application links, such as how many times you use a specific part of the Mobile Application over a given time period, the amount of time you spend using the Mobile Application, how often you use the Mobile Application, actions you take in the Mobile Application and how you engage with the Mobile Application Information to allow us to personalize the services and content available through the Mobile Application"),
                      Dimens.boxHeight24,

                      Text("What we do with the collected information", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "The purpose of collecting your information is to provide you with best in class experience while using our Services. Based on your information like what features of the Services are used most, viewing your ride history, rate charts per trip, and to determine which features we need to focus on improving, including usage patterns and geographic locations to determine where we should offer or focus services, features and/or resources. The information provided by you while creating/registering for an account, we will send you a welcoming email to verify your username and password. We use the information collected from our Mobile Application so that we are able to serve you the correct app version depending on your device type, for troubleshooting and in some cases, marketing purposes. We use your Internet Protocol (IP) address to help diagnose problems with our computer server, and to administer our web site. Your IP address helps us to identify you, but contains no personal information about you. We will send you strictly service-related announcements on rare occasions when it is necessary to do so. For instance, if any update regarding our services, we might send you an email. If you do not wish to receive them, you have the option to deactivate your account by sending an email to us. We may use the information obtained from you to prevent, discover and investigate violations of this Privacy Policy or any applicable terms of service or terms of use for the Mobile Application, and to investigate fraud or other matters. We share some of your confidential Information (such as your name, pick up address, contact number) to the driver who accepts your request for transportation so that the driver may contact and find you. We take your GPS/demographic location information for various purposes, which includes, for you to be check the availability of drivers in your area no restricted to any numbers that are close to your location, for enabling you to pin/enter your location from where driver can pick you, to send various offers that company may offer time to time",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("How third parties are involved in viewing your information", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "We do not sell, share, rent or trade the information we have collected about you, other than as disclosed within this Privacy Policy or at the time you provide your information. We may share few of your information like mobile number to third parties on our behalf to facilitate our Services, provide or perform certain aspects of the Services on our behalf - design and/or operate the Services’ features, track the Services’ analytics, process payments, engage in anti-fraud and security measures, provide GPS/Demographic Location information to our drivers, enable us to send you special offers, sending messages/notification related to every ride, perform technical services (e.g., without limitation, maintenance services, database management, web analytics and improvement of the Services‘ features), or perform other administrative services. These third parties will have access to user information, including Protected Information to only carry out the services they are performing for you or for us. We use a third party hosting provider who hosts our support section of our website.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight8,
                      Text(
                        "Information collected within this section of our website by such third party is governed by our Privacy Policy. Also, we cooperate with Government and law enforcement officials and private parties to enforce and comply with the law. Thus, we may access, use, preserve, transfer and disclose your information (including Protected Information, IP address, Device Information or geo-location data), to Government or law enforcement officials or private parties as we reasonably determine is necessary and appropriate:",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight12,
                      bulletPoint("to satisfy any applicable law, regulation, subpoenas, Governmental requests or legal process;"),
                      bulletPoint("to protect and/or defend the Terms and Conditions for online and mobile Services or other policies applicable to any online and mobile Services, including investigation of potential violations thereof;"),
                      bulletPoint("to protect the safety, rights, property or security of the Company, our Services or any third party;"),
                      bulletPoint("to protect the safety of the public for any reason;"),
                      bulletPoint("to detect, prevent or otherwise address fraud, security or technical issues; and /or"),
                      bulletPoint("to prevent or stop activity we may consider to be, or to pose a risk of being, an illegal, unethical, or legally actionable activity."),
                      bulletPoint("The Services may contain content that is supplied by a third party, and those third parties may collect website usage information and your Device Identifier when web pages from any online or mobile Services are served to your browser."),
                      Dimens.boxHeight24,

                      Text("Information shared with Drivers", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "This Privacy Policy shall not cover the usage of any information about you which is obtained by the driver or the company to which the driver belongs, while providing you a ride on a cab booked using our mobile application, or otherwise, which is not provided by us.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("Changes in information and Cancellation of Account", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "You should be held responsible for maintaining the accuracy of the information you submit to us by any means at the time of Creating/registering/Updating your account, such as your basic information, phone number etc. If you want to change, or if you no longer want our Services, you may correct, delete inaccuracies, or amend information by contacting us through email address mentioned on our website or Mobile Application. The changes take 24 hrs to 48 hrs to reflect in our system.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight8,
                      Text(
                        "You may also cancel or modify your communications that you have elected to receive from the Services by following the instructions contained within an e-mail or by logging into your user account and changing your communication preferences.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight8,
                      Text(
                        "If upon modifying or changing the information earlier provided to Us, we find it difficult to permit access to our Services to you due to insufficiency/inaccuracy of the information, we may, in our sole discretion terminate your access to the Services by providing you a written notice to this effect on your registered email id.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight8,
                      Text(
                        "For cancelling your account or request that we no longer use your information to provide you services, contact us through email address mentioned on our website and Mobile APP. We will retain your Protected Information and Usage Information (including GPS/Demographic Location) for as long as your account with the Services is active and as needed to provide you services. Even after your account is terminated, we will retain your Protected Information and Usage Information (including GPS/Demographic Location, Ride history, and any other record) as needed to comply with our legal and regulatory obligations, resolve disputes, conclude any activities related to cancellation of an account, investigate or prevent fraud and other inappropriate activity, to enforce our agreements, and for other business reason. After a period of time, your data may be anonymized and aggregated, and then may be held by us as long as necessary for us to provide our Services effectively, but our use of the anonymized data will be solely for analytic purposes.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("Security", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Your Information collected by us is securely stored within our databases, and we use standard, industry-wide, commercially reasonable security practices such as encryption, firewalls and SSL (Secure Socket Layers) for protecting your information. However, as effective as encryption technology is, no security system is impenetrable. We cannot guarantee the security of our databases, nor can we guarantee that information you supply won't be intercepted while being transmitted to us over the Internet or wireless communication, and any information you transmit to the Company you do at your own risk. We recommend that you not disclose your password to anyone at any time.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("Grievance Officer", style: headingStyle),
                      Dimens.boxHeight8,
                      RichText(
                        text: TextSpan(
                          style: contentStyle,
                          children: const [
                            TextSpan(text: "We have a separate division for any grievance for the purposes of the rules drafted under the Information Technology Act, 2000, which can be contacted at "),
                            TextSpan(text: "business@bambamcabs.com", style: TextStyle(color: Color(0xFF0088FF))),
                            TextSpan(text: ". You may address any grievances you may have in respect of this privacy policy or usage of your Confidential Information or other data to this id."),
                          ],
                        ),
                      ),
                      Dimens.boxHeight24,

                      Text("Changes to the privacy policy", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "We may update this Privacy Policy to reflect changes to our information practices at any point. Any changes will be effective immediately upon the posting of the revised Privacy Policy. If we make any material changes, we will notify you by email (sent to the e-mail address specified in your account) or by means of a notice on the Services prior to the change becoming effective. We recommend you to review this page for the latest information on our privacy practices.",
                        style: contentStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

