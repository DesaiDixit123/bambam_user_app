import 'package:bam_bam_user/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle heroTitleStyle = const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0B1727));
    TextStyle heroSubtitleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF5E6E82));
    TextStyle headingStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF5A00));
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
                      Text("Terms & Conditions", style: heroTitleStyle, textAlign: TextAlign.center),
                      Dimens.boxHeight12,
                      Text(
                        "Before you ride with BamBam, please take a moment to understand the terms that guide our services. These conditions ensure a fair, transparent, and smooth experience for every traveler.",
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
                      bulletPoint("The terms \"We\" / \"Us\" / \"Our\"/”Company” individually and collectively refer to Bam Bam Cabs c/o BAM BAM MOBILITY and the terms \"You\" /\"Your\"/\"Yourself\" refer to the users/drivers."),
                      bulletPoint("This Privacy Policy is an electronic record in the form of an electronic contract formed under the information Technology Act, 2000 and the rules made thereunder and the amended provisions pertaining to electronic documents / records in various statutes as amended by the information Technology Act, 2000. This Privacy Policy does not require any physical, electronic or digital signature."),
                      bulletPoint("This Privacy Policy is a legally binding document between you and Bam Bam Cabs c/o BAM BAM MOBILITY(both terms defined below). The terms of this Privacy Policy will be effective upon your acceptance of the same (directly or indirectly in electronic form, by clicking on the I accept tab or by use of the website or by other means) and will govern the relationship between you and BAM BAM MOBILITY for your use of the website “Website” (defined below)"),
                      bulletPoint("This document is published and shall be construed in accordance with the provisions of the Information Technology (reasonable security practices and procedures and sensitive personal data of information) rules, 2011 under Information Technology Act, 2000; that require publishing of the Privacy Policy for collection, use, storage and transfer of sensitive personal data or information."),
                      bulletPoint("Please read this Privacy Policy carefully by using the Website i.e. www.bambamcabs.com, you indicate that you understand, agree and consent to this Privacy Policy. If you do not agree with the terms of this Privacy Policy, please do not use this Website."),
                      bulletPoint("By providing us your Information or by making use of the facilities provided by the Website, You hereby consent to the collection, storage, processing and transfer of any or all of Your Personal Information and Non-Personal Information by us as specified under this Privacy Policy. You further agree that such collection, use, storage and transfer of Your Information shall not cause any loss or wrongful gain to you or any other person."),
                      Dimens.boxHeight24,

                      Text("1. Acceptance of Terms", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "By accessing or using our Service, you agree to these Terms and Conditions and acknowledge that you have read our Privacy Policy. If you do not agree with these terms, please do not use our Service.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("2. User Eligibility", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "You must be at least 18 years of age to use our Service. By using our Service, you represent and warrant that you are of legal age and have the legal capacity to enter into this agreement.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("3. Service Description", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Bam Bam Cabs provides an online platform that connects users with independent third-party transportation providers. Users can request transportation services through the Bam Bam Cabs mobile application or website.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("4. User Responsibilities", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "You are responsible for providing accurate and complete information when using our Service.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight8,
                      Text(
                        "You agree not to misuse our Service or engage in any unlawful activities while using it.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("5. Payment and Billing", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Payments for the transportation services will be handled through the Bam Bam Cabs platform. Users agree to pay for the services as specified on the platform. Bam Bam Cabs may use third-party payment processors and your use of their services is subject to their terms and conditions.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("6. Cancellation and Refund Policy", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Bam Bam Cabs may have a cancellation and refund policy in place. Users are encouraged to review this policy on the Bam Bam Cabs website or mobile application.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("7. User Conduct", style: headingStyle),
                      Dimens.boxHeight8,
                      Text("You agree not to:", style: contentStyle),
                      Dimens.boxHeight8,
                      bulletPoint("Engage in any activities that may harm the reputation or functioning of Bam Bam Cabs."),
                      bulletPoint("Violate any local, state, or federal laws or regulations."),
                      bulletPoint("Interfere with the proper functioning of the Service."),
                      bulletPoint("Engage in any fraudulent or harmful activities."),
                      Dimens.boxHeight24,

                      Text("8. Privacy", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "We collect and use your personal information as described in our Privacy Policy. By using our Service, you consent to the collection and use of your personal information as outlined in the Privacy Policy.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("9. Termination", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Bam Bam Cabs reserves the right to suspend or terminate your access to the Service at its discretion, without notice, if you violate these terms.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("10. Disclaimer", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Bam Bam Cabs provides the Service on an \"as is\" and \"as available\" basis without warranties of any kind. We are not responsible for the actions or behavior of the transportation providers.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("11. Limitation of Liability", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Bam Bam Cabs is not liable for any direct, indirect, incidental, or consequential damages arising from the use of our Service.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("12. Changes to Terms", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "Bam Bam Cabs reserves the right to modify these Terms and Conditions at any time. Users will be notified of any changes through the Service.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("13. Intellectual Property", style: headingStyle),
                      Dimens.boxHeight8,
                      Text(
                        "The Bam Bam Cabs website and mobile application, including all content and intellectual property, are owned and operated by BAM BAM MOBILITY. Users are not granted any rights to use our intellectual property without prior written consent.",
                        style: contentStyle,
                      ),
                      Dimens.boxHeight24,

                      Text("14. Contact Information", style: headingStyle),
                      Dimens.boxHeight8,
                      RichText(
                        text: TextSpan(
                          style: contentStyle,
                          children: const [
                            TextSpan(text: "If you have any questions or concerns regarding these terms, please contact us at\n"),
                            TextSpan(text: "business@bambamcabs.com", style: TextStyle(color: Color(0xFF0088FF))),
                            TextSpan(text: "."),
                          ],
                        ),
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
