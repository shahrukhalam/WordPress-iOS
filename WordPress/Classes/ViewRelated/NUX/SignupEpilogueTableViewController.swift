import UIKit
import WordPressAuthenticator

protocol SignupEpilogueTableViewControllerDelegate {
    func displayNameUpdated(newDisplayName: String)
    func displayNameAutoGenerated(newDisplayName: String)
    func passwordUpdated(newPassword: String)
    func usernameTapped(userInfo: LoginEpilogueUserInfo?)
}

/// Data source to get the temporary user info, not yet saved in the user account.
///
protocol SignupEpilogueTableViewControllerDataSource {
    var customDisplayName: String? { get }
    var password: String? { get }
    var username: String? { get }
}

class SignupEpilogueTableViewController: UITableViewController, EpilogueUserInfoCellViewControllerProvider {

    // MARK: - Properties

    open var dataSource: SignupEpilogueTableViewControllerDataSource?
    open var delegate: SignupEpilogueTableViewControllerDelegate?
    open var credentials: AuthenticatorCredentials?
    open var socialService: SocialService?

    private var epilogueUserInfo: LoginEpilogueUserInfo?
    private var userInfoCell: EpilogueUserInfoCell?
    private var showPassword: Bool = true
    private var reloaded: Bool = false

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .basicBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getUserInfo()
        configureTable()
        if reloaded {
            tableView.reloadData()
        }
        reloaded = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard section != TableSections.userInfo else {
            return Constants.userInfoRows
        }

        return showPassword ? Constants.allAccountRows : Constants.noPasswordRows
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Don't show section header for User Info
        guard section != TableSections.userInfo,
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellIdentifiers.sectionHeaderFooter) as? EpilogueSectionHeaderFooter else {
            return nil
        }

        cell.contentView.backgroundColor = .basicBackground
        cell.titleLabel?.text = NSLocalizedString("Account Details", comment: "Header for account details, shown after signing up.").localizedUppercase
        cell.titleLabel?.accessibilityIdentifier = "New Account Header"
        cell.accessibilityLabel = cell.titleLabel?.text

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

        guard section != TableSections.userInfo,
            showPassword,
            let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellIdentifiers.sectionHeaderFooter) as? EpilogueSectionHeaderFooter else {
                return nil
        }

        cell.contentView.backgroundColor = .basicBackground
        cell.titleLabel?.numberOfLines = 0
        cell.topConstraint.constant = Constants.footerTopMargin
        cell.titleLabel?.text = NSLocalizedString("You can always log in with a link like the one you just used, but you can also set up a password if you prefer.", comment: "Information shown below the optional password field after new account creation.")
        cell.accessibilityLabel = cell.titleLabel?.text

        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // User Info Row
        if indexPath.section == TableSections.userInfo {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.epilogueUserInfoCell) as? EpilogueUserInfoCell else {
                return UITableViewCell()
            }

            if let epilogueUserInfo = epilogueUserInfo {
                cell.configure(userInfo: epilogueUserInfo, showEmail: true, allowGravatarUploads: true)
            }
            cell.viewControllerProvider = self
            userInfoCell = cell
            return cell
        }

        // Account Details Rows
        guard let cellType = EpilogueCellType(rawValue: indexPath.row) else {
            return UITableViewCell()
        }

        return getEpilogueCellFor(cellType: cellType)

    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Constants.headerFooterHeight
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == TableSections.userInfo ? 0 : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return Constants.headerFooterHeight
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section != TableSections.userInfo, showPassword else {
            return 0
        }

        return UITableView.automaticDimension
    }

}

// MARK: - Private Extension

private extension SignupEpilogueTableViewController {

    func configureTable() {
        let headerFooterNib = UINib(nibName: CellNibNames.sectionHeaderFooter, bundle: nil)
        tableView.register(headerFooterNib, forHeaderFooterViewReuseIdentifier: CellIdentifiers.sectionHeaderFooter)

        let cellNib = UINib(nibName: CellNibNames.signupEpilogueCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: CellIdentifiers.signupEpilogueCell)

        let userInfoNib = UINib(nibName: CellNibNames.epilogueUserInfoCell, bundle: nil)
        tableView.register(userInfoNib, forCellReuseIdentifier: CellIdentifiers.epilogueUserInfoCell)

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.backgroundColor = .basicBackground

        // remove empty cells
        tableView.tableFooterView = UIView()
    }

    func getUserInfo() {

        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        guard let account = service.defaultWordPressComAccount() else {
            return
        }

        var userInfo = LoginEpilogueUserInfo(account: account)
        if let socialservice = socialService {
            showPassword = false
            userInfo.update(with: socialservice)
        } else {
            if let customDisplayName = dataSource?.customDisplayName {
                userInfo.fullName = customDisplayName
            } else {
                let autoDisplayName = generateDisplayName(from: userInfo.email)
                userInfo.fullName = autoDisplayName
                delegate?.displayNameAutoGenerated(newDisplayName: autoDisplayName)
            }
        }
        epilogueUserInfo = userInfo
    }

    func generateDisplayName(from rawEmail: String) -> String {
        // step 1: lower case
        let email = rawEmail.lowercased()
        // step 2: remove the @ and everything after
        let localPart = email.split(separator: "@")[0]
        // step 3: remove all non-alpha characters
        let localCleaned = localPart.replacingOccurrences(of: "[^A-Za-z/.]", with: "", options: .regularExpression)
        // step 4: turn periods into spaces
        let nameLowercased = localCleaned.replacingOccurrences(of: ".", with: " ")
        // step 5: capitalize
        let autoDisplayName = nameLowercased.capitalized

        return autoDisplayName
    }

    func getEpilogueCellFor(cellType: EpilogueCellType) -> SignupEpilogueCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.signupEpilogueCell) as? SignupEpilogueCell else {
            return SignupEpilogueCell()
        }

        switch cellType {
        case .displayName:
            cell.configureCell(forType: .displayName,
                               labelText: NSLocalizedString("Display Name", comment: "Display Name label text."),
                               fieldValue: dataSource?.customDisplayName ?? epilogueUserInfo?.fullName)
        case .username:
            cell.configureCell(forType: .username,
                               labelText: NSLocalizedString("Username", comment: "Username label text."),
                               fieldValue: dataSource?.username ?? epilogueUserInfo?.username)
        case .password:
            cell.configureCell(forType: .password,
                               fieldValue: dataSource?.password,
                               fieldPlaceholder: NSLocalizedString("Password (optional)", comment: "Password field placeholder text"))
        }

        cell.delegate = self
        return cell
    }

    struct Constants {
        static let numberOfSections = 2
        static let userInfoRows = 1
        static let noPasswordRows = 2
        static let allAccountRows = 3
        static let headerFooterHeight: CGFloat = 50
        static let footerTrailingMargin: CGFloat = 16
        static let footerTopMargin: CGFloat = 8
    }

    struct TableSections {
        static let userInfo = 0
    }

    struct CellIdentifiers {
        static let sectionHeaderFooter = "SectionHeaderFooter"
        static let signupEpilogueCell = "SignupEpilogueCell"
        static let epilogueUserInfoCell = "userInfo"
    }

    struct CellNibNames {
        static let sectionHeaderFooter = "EpilogueSectionHeaderFooter"
        static let signupEpilogueCell = "SignupEpilogueCell"
        static let epilogueUserInfoCell = "EpilogueUserInfoCell"
    }
}

// MARK: - SignupEpilogueCellDelegate

extension SignupEpilogueTableViewController: SignupEpilogueCellDelegate {

    func updated(value: String, forType: EpilogueCellType) {
        switch forType {
        case .displayName:
            delegate?.displayNameUpdated(newDisplayName: value)
        case .password:
            delegate?.passwordUpdated(newPassword: value)
        default:
            break
        }
    }

    func changed(value: String, forType: EpilogueCellType) {
        if forType == .displayName {
            userInfoCell?.fullNameLabel?.text = value
            delegate?.displayNameUpdated(newDisplayName: value)
        } else if forType == .password {
            delegate?.passwordUpdated(newPassword: value)
        }
    }

    func usernameSelected() {
        delegate?.usernameTapped(userInfo: epilogueUserInfo)
    }

}
