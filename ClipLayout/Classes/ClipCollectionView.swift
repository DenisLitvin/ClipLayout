//
//  ClipCollectionView.swift
//  ClipLayout
//
//  Created by Denis Litvin on 31.07.2018.
//

import UIKit

public protocol DataBinder {
    associatedtype Data
    func set(data: Data)
}

public class ClipCollectionView<Cell: DataBinder>:
    UICollectionView,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
    where Cell: ClipCell
{
    
    public var data: [Cell.Data] = []
    public let cellId = "cellId"
    public var cellWidth: CGFloat?
    
    private let manequinCell = Cell()
    
    public init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
        register(Cell.self, forCellWithReuseIdentifier: cellId)
        self.dataSource = self
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? Cell
            else { fatalError("Could not dequeue Cell") }
        cell.set(data: data[indexPath.row])
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        manequinCell.set(data: data[indexPath.row])
        let size = manequinCell.clip.measureSize(within: CGSize(width: cellWidth ?? collectionView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        manequinCell.clip.invalidateCache()
        return CGSize(width: cellWidth ?? collectionView.bounds.width, height: size.height)
    }
}

public class ClipCell: UICollectionViewCell {
    override public func layoutSubviews() {
        super.layoutSubviews()
        clip.layoutSubviews()
    }
}
