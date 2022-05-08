import UIKit

class KivaLoanTableViewController: UITableViewController {
    
    private let kivaLoanURL = "https://api.kivaws.org/v1/loans/newest.json"
    private var loans = [Loan]()
    
    enum Section {
        case all
    }
    
    lazy var dataSource = configureDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 92.0
        tableView.rowHeight = UITableView.automaticDimension
        
        getLatestLoans()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getLatestLoans() {
        guard let loanURL = URL(string: kivaLoanURL) else {
            return
        }
        
        let request = URLRequest(url: loanURL)
        let task = URLSession.shared.dataTask(with: request) { data, response, err in
            if let err = err {
                print(err)
                return
            } else {
                if let data = data {
                    self.loans = self.parseJSON(data: data)
                    
                    OperationQueue.main.addOperation {
                        self.updateSnapshot()
                    }
                }
            }
        }
        task.resume()
    }
    
    func parseJSON(data: Data) -> [Loan] {
        
        var loans = [Loan]()
        do {
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
            
            let jsonLoans = jsonResult?["loans"] as! [AnyObject]
            for jsonLoan in jsonLoans {
                var loan = Loan()
                loan.name = jsonLoan["name"] as! String
                let location = jsonLoan["location"] as! [String:AnyObject]
                loan.country = location["country"] as! String
                loan.use = jsonLoan["use"] as! String
                loan.amount = jsonLoan["loan_amount"] as! Int
                
                loans.append(loan)
            }
        } catch {
            print(error)
        }
        
        return loans
    }
    
    func configureDataSource() -> UITableViewDiffableDataSource<Section, Loan> {
        
        let cellIdentifier = "Cell"
        
        let dataSource = UITableViewDiffableDataSource<Section, Loan>(tableView: tableView) { tableView, indexPath, loan in
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! KivaLoanTableViewCell
            cell.nameLabel.text = loan.name
            cell.countryLabel.text = loan.country
            cell.useLabel.text = loan.use
            cell.amountLabel.text = String(loan.amount)
            
            return cell
        }
        
        return dataSource
    }
    
    func updateSnapshot(animatingChange: Bool = false) {
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Loan>()
        snapshot.appendSections([.all])
        snapshot.appendItems(loans, toSection: .all)
        
        dataSource.apply(snapshot, animatingDifferences: animatingChange)
    }
}
