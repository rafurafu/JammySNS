//利用規約

import SwiftUI

struct SettingServiceView: View {
    @State private var selectedLanguage = 0
    @EnvironmentObject private var termsViewModel: TermsViewModel
    
    var body: some View {
        VStack {
            if selectedLanguage == 0 {
                Text("アプリを開始するには、利用規約に同意してください。")
                    .fontWeight(.bold)
                    .padding()
            } else {
                Text("To start the app, accept the terms of conditions.")
                    .fontWeight(.bold)
                    .padding()
            }
            
            Picker("Language", selection: $selectedLanguage) {
                Text("日本語").tag(0)
                Text("English").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selectedLanguage == 0 {
                        JapaneseTermsView()
                    } else {
                        EnglishTermsView()
                    }
                }
                .padding()
            }
            
            if selectedLanguage == 0 {
                Button {
                    termsViewModel.hasAgreedToTerms = true
                } label: {
                    Text("利用規約に同意する")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
            } else {
                Button {
                    termsViewModel.hasAgreedToTerms = true
                } label: {
                    Text("Accept the terms of use")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
            }
        }
    }
}

// 日本語の利用規約
struct JapaneseTermsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("利用規約")
                .font(.title)
                .bold()
            
            Group {
                Text("この利用規約（以下，「本規約」といいます。）は，a Bros.（以下，「開発者」といいます。）がこのアプリ上で提供するサービス（以下，「本サービス」といいます。）の利用条件を定めるものです。登録ユーザーの皆さま（以下，「ユーザー」といいます。）には，本規約に従って，本サービスをご利用いただきます。")
            }
            
            Group {
                Text("第1条（適用）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 本規約は，ユーザーと開発者との間の本サービスの利用に関わる一切の関係に適用されるものとします。")
                Text("2. 開発者は本サービスに関し，本規約のほか，ご利用にあたってのルール等，各種の定め（以下，「個別規定」といいます。）をすることがあります。これら個別規定はその名称のいかんに関わらず，本規約の一部を構成するものとします。")
                Text("3. 本規約の規定が前条の個別規定の規定と矛盾する場合には，個別規定において特段の定めなき限り，個別規定の規定が優先されるものとします。")
            }
            
            Group {
                Text("第2条（利用登録）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 本サービスにおいては，登録希望者が本規約に同意の上，開発者の定める方法によって利用登録を申請し，開発者がこの承認を登録希望者に通知することによって，利用登録が完了するものとします。")
                Text("2. 開発者は，利用登録の申請者に以下の事由があると判断した場合，利用登録の申請を承認しないことがあり，その理由については一切の開示義務を負わないものとします。")
                Text("   a. 利用登録の申請に際して虚偽の事項を届け出た場合")
                Text("   b. 本規約に違反したことがある者からの申請である場合")
                Text("   c. その他，開発者が利用登録を相当でないと判断した場合")
            }
            
            Group {
                Text("第3条（ユーザーIDおよびパスワードの管理）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. ユーザーは，自己の責任において，本サービスのユーザーIDおよびパスワードを適切に管理するものとします。")
                Text("2. ユーザーは，いかなる場合にも，ユーザーIDおよびパスワードを第三者に譲渡または貸与し，もしくは第三者と共用することはできません。")
                Text("3. 開発者は，ユーザーIDとパスワードの組み合わせが登録情報と一致してログインされた場合には，そのユーザーIDを登録しているユーザー自身による利用とみなします。")
                Text("4. ユーザーID及びパスワードが第三者によって使用されたことによって生じた損害は，開発者に故意又は重大な過失がある場合を除き，開発者は一切の責任を負わないものとします。")
            }
            
            Group {
                Text("第4条（利用料金および支払方法）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 本サービスの利用は無料とします。")
                Text("2. 開発者は，本サービスの利用料金を変更する場合には，変更日の1ヶ月前までにユーザーに通知するものとします。")
            }
            
            Group {
                Text("第5条（禁止事項）")
                    .font(.headline)
                    .padding(.top)
                
                Text("ユーザーは，本サービスの利用にあたり，以下の行為をしてはなりません。")
                Text("1. 法令または公序良俗に違反する行為")
                Text("2. 犯罪行為に関連する行為")
                Text("3. 開発者，本サービスの他のユーザー，または第三者のサーバーまたはネットワークの機能を破壊したり，妨害したりする行為")
                Text("4. 開発者のサービスの運営を妨害するおそれのある行為")
                Text("5. 他のユーザーに関する個人情報等を収集または蓄積する行為")
                Text("6. 不正アクセスをし，またはこれを試みる行為")
                Text("7. 他のユーザーに成りすます行為")
                Text("8. 開発者のサービスに関連して，反社会的勢力に対して直接または間接に利益を供与する行為")
                Text("9. 開発者，本サービスの他のユーザーまたは第三者の知的財産権，肖像権，プライバシー，名誉その他の権利または利益を侵害する行為")
                Text("10. 以下の表現を含み，または含むと開発者が判断する内容を本サービス上に投稿し，または送信する行為")
                Text("    a. 過度に暴力的な表現")
                Text("    b. 露骨な性的表現")
                Text("    c. 人種，国籍，信条，性別，社会的身分，門地等による差別につながる表現")
                Text("    d. 自殺，自傷行為，薬物乱用を誘引または助長する表現")
                Text("    e. その他反社会的な内容を含み他人に不快感を与える表現")
            }
            
            Group {
                Text("第6条（本サービスの提供の停止等）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 開発者は，以下のいずれかの事由があると判断した場合，ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。")
                Text("   a. 本サービスにかかるコンピュータシステムの保守点検または更新を行う場合")
                Text("   b. 地震，落雷，火災，停電，天災またはウイルスの蔓延などの不可抗力により，本サービスの提供が困難となった場合")
                Text("   c. コンピュータまたは通信回線等が事故により停止した場合")
                Text("   d. その他，開発者が本サービスの提供が困難と判断した場合")
                Text("2. 本サービスの提供が停止または中断したことにより，ユーザーまたは第三者が被ったいかなる不利益または損害についても，開発者は一切の責任を負わないものとします。")
            }
            
            Group {
                Text("第7条（著作権等の取り扱い）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. ユーザーは，自ら著作権等の必要な知的財産権を有するか，または必要な権利者の許諾を得た文章，画像や映像等の情報に関してのみ，本サービスを利用し，投稿ないしアップロードすることができるものとします。")
                Text("2. ユーザーが本サービスを利用して投稿ないしアップロードした文章，画像，映像等の著作権については，当該ユーザーその他既存の権利者に留保されるものとします。ただし，開発者は，本サービスを利用して投稿ないしアップロードされた文章，画像，映像等について，本サービスの改良，品質の向上，または不備の是正等ならびに本サービスの周知宣伝等に必要な範囲で利用できるものとし，ユーザーは，この利用に関して，著作者人格権を行使しないものとします。")
                Text("3. 前項本文の定めるものを除き，本サービスおよび本サービスに関連する一切の情報についての著作権およびその他の知的財産権はすべて開発者または開発者にその利用を許諾した権利者に帰属し，ユーザーは無断で複製，譲渡，貸与，翻訳，改変，転載，公衆送信（送信可能化を含みます。），伝送，配布，出版，営業使用等をしてはならないものとします。")
            }
            
            Group {
                Text("第8条（利用制限および登録抹消）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 開発者は，ユーザーが以下のいずれかに該当する場合には，事前の通知なく，投稿データを削除し，ユーザーに対して本サービスの全部もしくは一部の利用を制限しまたはユーザーとしての登録を抹消することができるものとします。")
                Text("   a. 本規約のいずれかの条項に違反した場合")
                Text("   b. 登録事項に虚偽の事実があることが判明した場合")
                Text("   c. 開発者からの連絡に対し，一定期間返答がない場合")
                Text("   d. 本サービスについて，最終の利用から一定期間利用がない場合")
                Text("   e. その他，開発者が本サービスの利用を適当でないと判断した場合")
                Text("2. 前項各号のいずれかに該当した場合，ユーザーは，当然に開発者に対する一切の債務について期限の利益を失い，その時点において負担する一切の債務を直ちに一括して弁済しなければなりません。")
                Text("3. 開発者は，本条に基づき開発者が行った行為によりユーザーに生じた損害について，一切の責任を負いません。")
            }
            
            Group {
                Text("第9条（退会およびデータの取り扱い）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. ユーザーは，開発者の定める退会手続により，本サービスから退会できるものとします。")
                Text("2. 退会後のユーザーのデータについては，開発者は退会後30日間保持し，その後削除するものとします。")
                Text("3. 退会後のデータの復旧はできないものとします。")
            }
            
            Group {
                Text("第10条（データの保持およびバックアップ）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 開発者は，本サービスのデータについて定期的なバックアップを行います。")
                Text("2. 開発者は，データの保持期間を1年間とし，その経過後は事前の通知なく削除できるものとします。")
                Text("3. ユーザーは，自己の責任において必要なデータのバックアップを行うものとします。")
            }
            
            Group {
                Text("第11条（保証の否認および免責事項）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 開発者は，本サービスに事実上または法律上の瑕疵（安全性，信頼性，正確性，完全性，有効性，特定の目的への適合性，セキュリティなどに関する欠陥，エラーやバグ，権利侵害などを含みます。）がないことを明示的にも黙示的にも保証しておりません。")
                Text("2. 開発者は，本サービスに起因してユーザーに生じたあらゆる損害について一切の責任を負いません。ただし，本サービスに関する開発者とユーザーとの間の契約（本規約を含みます。）が消費者契約法に定める消費者契約となる場合，この免責規定は適用されません。")
                Text("3. 前項ただし書に定める場合であっても，開発者は，開発者の過失（重過失を除きます。）による債務不履行または不法行為によりユーザーに生じた損害のうち特別な事情から生じた損害（開発者またはユーザーが損害発生につき予見し，または予見し得た場合を含みます。）について一切の責任を負いません。")
                Text("4. 開発者は，本サービスに関して，ユーザーと他のユーザーまたは第三者との間において生じた取引，連絡または紛争等について一切責任を負いません。")
            }
            
            Group {
                Text("第12条（サービス内容の変更等）")
                    .font(.headline)
                    .padding(.top)
                
                Text("開発者は，ユーザーに通知することなく，本サービスの内容を変更しまたは本サービスの提供を中止することができるものとし，これによってユーザーに生じた損害について一切の責任を負いません。")
            }
            
            Group {
                Text("第13条（利用規約の変更）")
                    .font(.headline)
                    .padding(.top)
                
                Text("開発者は，必要と判断した場合には，ユーザーに通知することなくいつでも本規約を変更することができるものとします。なお，本規約の変更後，本サービスの利用を開始した場合には，当該ユーザーは変更後の規約に同意したものとみなします。")
            }
            
            Group {
                Text("第14条（個人情報の取扱い）")
                    .font(.headline)
                    .padding(.top)
                
                Text("開発者は，本サービスの利用によって取得する個人情報については，開発者「プライバシーポリシー」に従い適切に取り扱うものとします。")
            }
            
            Group {
                Text("第15条（通知または連絡）")
                    .font(.headline)
                    .padding(.top)
                
                Text("ユーザーと開発者との間の通知または連絡は，開発者の定める方法によって行うものとします。開発者は，ユーザーから，開発者が別途定める方式に従った変更届け出がない限り，現在登録されている連絡先が有効なものとみなして当該連絡先へ通知または連絡を行い，これらは，発信時にユーザーへ到達したものとみなします。")
            }
            
            Group {
                Text("第16条（権利義務の譲渡の禁止）")
                    .font(.headline)
                    .padding(.top)
                
                Text("ユーザーは，開発者の書面による事前の承諾なく，利用契約上の地位または本規約に基づく権利もしくは義務を第三者に譲渡し，または担保に供することはできません。")
            }
            
            Group {
                Text("第17条（準拠法・裁判管轄）")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. 本規約の解釈にあたっては，日本法を準拠法とします。")
                Text("2. 本サービスに関して紛争が生じた場合には，開発者の本店所在地を管轄する裁判所を専属的合意管轄とします。")
            }
            
            Group {
                Text("お問合せ")
                    .font(.headline)
                    .padding(.top)
                
                Text("本規約に関するお問い合わせは，下記の窓口までお願いします。")
                Text("メールアドレス：alphabros.jammy@gmail.com")
            }
            
            Text("2024年10月30日制定")
                .padding(.top)
        }
    }
}

// 英語版の実装
struct EnglishTermsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Terms of Service")
                .font(.title)
                .bold()
            
            Group {
                Text("These Terms of Service (\"Terms\") define the terms and conditions of use for the service (\"Service\") provided on this app by a Bros. (\"Developer\"). Registered users (\"Users\") agree to these Terms and use the Service accordingly.")
            }
            
            Group {
                Text("Article 1 (Applicability)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. These Terms apply to all relationships between Users and the Developer regarding the use of the Service.")
                Text("2. The Developer may establish additional rules and provisions (\"Individual Provisions\") for using the Service. These Individual Provisions, regardless of their name, form part of these Terms.")
                Text("3. In case of any conflict between these Terms and Individual Provisions, the Individual Provisions shall prevail unless otherwise specified.")
            }
            
            Group {
                Text("Article 2 (Registration)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. To register for the Service, users must agree to these Terms and apply through the method specified by the Developer. Registration is complete when the Developer approves and notifies the applicant.")
                Text("2. The Developer may refuse registration without disclosing reasons if the applicant:")
                Text("   a. Provides false information during registration")
                Text("   b. Has previously violated these Terms")
                Text("   c. Is otherwise deemed unsuitable by the Developer")
            }
            
            Group {
                Text("Article 3 (User ID and Password Management)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. Users are responsible for properly managing their Service user ID and password.")
                Text("2. Users may not transfer, lend, or share their user ID and password with any third party under any circumstances.")
                Text("3. When a login occurs with a matching user ID and password combination, the Developer will consider it as use by the registered user of that ID.")
                Text("4. The Developer assumes no responsibility for damages caused by third-party use of user IDs and passwords, except in cases of intentional or gross negligence by the Developer.")
            }
            
            Group {
                Text("Article 4 (Service Fees and Payment)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. Use of the Service is free of charge.")
                Text("2. If the Developer changes the Service fees, users will be notified one month prior to the change.")
            }
            
            Group {
                Text("Article 5 (Prohibited Activities)")
                    .font(.headline)
                    .padding(.top)
                
                Text("Users shall not engage in the following activities when using the Service:")
                Text("1. Activities that violate laws or public order and morals")
                Text("2. Activities related to criminal conduct")
                Text("3. Activities that destroy or interfere with the functionality of servers or networks of the Developer, other users, or third parties")
                Text("4. Activities that may interfere with Service operations")
                Text("5. Collecting or storing personal information about other users")
                Text("6. Unauthorized access or attempts to gain unauthorized access")
                Text("7. Impersonating other users")
                Text("8. Providing direct or indirect benefits to anti-social forces in connection with the Service")
                Text("9. Infringing on intellectual property rights, publicity rights, privacy, reputation, or other rights or interests of the Developer, other users, or third parties")
                Text("10. Posting or transmitting content on the Service that includes or is deemed by the Developer to include:")
                Text("    a. Excessively violent expressions")
                Text("    b. Explicit sexual content")
                Text("    c. Discriminatory expressions based on race, nationality, beliefs, gender, social status, family origin, etc.")
                Text("    d. Content promoting or encouraging suicide, self-harm, or drug abuse")
                Text("    e. Other antisocial content that may cause discomfort to others")
            }
            
            Group {
                Text("Article 6 (Service Suspension)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. The Developer may suspend or interrupt the Service in whole or in part without prior notice in the following cases:")
                Text("   a. When performing maintenance or updates on the Service's computer systems")
                Text("   b. When Service provision becomes difficult due to force majeure such as earthquakes, lightning, fire, power outages, natural disasters, or virus outbreaks")
                Text("   c. When computers or communication lines stop due to accidents")
                Text("   d. When the Developer otherwise determines Service provision is difficult")
                Text("2. The Developer shall not be liable for any disadvantages or damages incurred by users or third parties due to Service suspension or interruption.")
            }
            
            Group {
                Text("Article 7 (Copyright and Intellectual Property)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. Users may only post or upload content (text, images, videos, etc.) for which they own the necessary intellectual property rights or have obtained permission from rights holders.")
                Text("2. Copyright of content posted or uploaded through the Service remains with the user or original rights holder. However, the Developer may use such content as needed for Service improvement, quality enhancement, defect correction, and promotion, and users agree not to exercise their moral rights regarding such use.")
                Text("3. Except as provided above, all intellectual property rights related to the Service belong to the Developer or its licensors. Users may not reproduce, transfer, lend, translate, modify, reprint, transmit, distribute, publish, or use for business purposes without permission.")
            }
            
            Group {
                Text("Article 8 (Usage Restrictions and Account Deletion)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. The Developer may delete posted data, restrict Service use, or delete user registration without prior notice if:")
                Text("   a. The user violates any Terms provisions")
                Text("   b. Registration information is found to be false")
                Text("   c. The user fails to respond to Developer communications for a certain period")
                Text("   d. The user has not used the Service for an extended period")
                Text("   e. The Developer otherwise deems continued use inappropriate")
                Text("2. In such cases, users immediately lose all payment privileges and must pay any outstanding obligations to the Developer in full.")
                Text("3. The Developer bears no responsibility for damages resulting from actions taken under this article.")
            }
            
            Group {
                Text("Article 9 (Account Closure and Data Handling)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. Users may close their account through procedures specified by the Developer.")
                Text("2. The Developer will retain user data for 30 days after account closure, after which it will be deleted.")
                Text("3. Data cannot be recovered after deletion.")
            }
            
            Group {
                Text("Article 10 (Data Retention and Backup)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. The Developer performs regular backups of Service data.")
                Text("2. The Developer retains data for one year and may delete it without notice after this period.")
                Text("3. Users are responsible for backing up their necessary data.")
            }
            
            Group {
                Text("Article 11 (Disclaimer and Limitation of Liability)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. The Developer makes no express or implied warranties regarding the Service's absence of factual or legal defects (including safety, reliability, accuracy, completeness, effectiveness, fitness for a particular purpose, security issues, errors, bugs, or rights infringements).")
                Text("2. The Developer assumes no responsibility for any damages users incur from using the Service. However, this disclaimer does not apply if the agreement between the Developer and user qualifies as a consumer contract under the Consumer Contract Act.")
                Text("3. Even in cases covered by the preceding exception, the Developer is not liable for special damages arising from foreseeable circumstances or negligence (excluding gross negligence).")
                Text("4. The Developer assumes no responsibility for transactions, communications, or disputes between users or between users and third parties regarding the Service.")
            }
            
            Group {
                Text("Article 12 (Service Content Changes)")
                    .font(.headline)
                    .padding(.top)
                
                Text("The Developer may change Service content or discontinue the Service without notice and bears no responsibility for resulting damages.")
            }
            
            Group {
                Text("Article 13 (Terms of Service Changes)")
                    .font(.headline)
                    .padding(.top)
                
                Text("The Developer may modify these Terms at any time without notice. Continued Service use after changes indicates acceptance of the modified Terms.")
            }
            
            Group {
                Text("Article 14 (Personal Information Handling)")
                    .font(.headline)
                    .padding(.top)
                
                Text("The Developer handles personal information collected through the Service appropriately according to the Developer's Privacy Policy.")
            }
            
            Group {
                Text("Article 15 (Notifications and Communications)")
                    .font(.headline)
                    .padding(.top)
                
                Text("Notifications and communications between users and the Developer shall be conducted through Developer-specified methods. Messages sent to registered contact information are considered received upon transmission unless users have properly submitted contact information changes.")
            }
            
            Group {
                Text("Article 16 (Prohibition of Rights Transfer)")
                    .font(.headline)
                    .padding(.top)
                
                Text("Users may not transfer their position under the usage contract or any rights or obligations under these Terms to third parties, nor use them as collateral, without prior written consent from the Developer.")
            }
            
            Group {
                Text("Article 17 (Governing Law and Jurisdiction)")
                    .font(.headline)
                    .padding(.top)
                
                Text("1. These Terms shall be interpreted according to Japanese law.")
                Text("2. Any disputes regarding the Service shall be subject to the exclusive jurisdiction of the court with jurisdiction over the Developer's headquarters.")
            }
            
            Group {
                Text("Contact")
                    .font(.headline)
                    .padding(.top)
                
                Text("For questions or suggestions about these Terms of Service, please contact:")
                Text("Email: alphabros.jammy@gmail.com")
            }
            
            Text("These Terms of Service are effective as of October 30, 2024.")
                .padding(.top)
        }
    }
}

#Preview {
    SettingServiceView()
        .environmentObject(TermsViewModel())
}
