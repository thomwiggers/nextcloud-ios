//
//  NCApplicationHandle.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 25/11/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import NextcloudKit

class NCApplicationHandle: NSObject {

    let appDelegate = UIApplication.shared.delegate as? AppDelegate

    // class: AppDelegate
    // func: application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:])
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return false
    }

    // class: NCFunctionCenter
    // func: downloadedFile(_ notification: NSNotification)
    func downloadedFile(selector: String, metadata: tableMetadata) {
    }

    // class: NCCollectionViewCommon (+Menu)
    // func: toggleMenu(metadata: tableMetadata, imageIcon: UIImage?)
    func addCollectionViewCommonMenu(metadata: tableMetadata, imageIcon: UIImage?, actions: [NCMenuAction]) {
    }

    // class: NCMore
    // func: loadItems()
    func loadItems(functionMenu: [NKExternalSite]) {
    }

    // class: NCMore
    // func: tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func didSelectItem(_ item: NKExternalSite, viewController: UIViewController) {
    }
}