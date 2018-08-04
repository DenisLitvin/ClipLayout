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

open class ClipCollectionView<Cell: DataBinder>:
    UICollectionView,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
    where Cell: ClipCell
{
    
    public var data: [Cell.Data] = []
    public let cellId = "cellId"
    public var maxSize = CGSize.zero
    
    private let manequinCell = Cell()
    
    public init(collectionViewLayout layout: UICollectionViewLayout) {
        maxSize.height = .greatestFiniteMagnitude
        super.init(frame: .zero, collectionViewLayout: layout)
        register(Cell.self, forCellWithReuseIdentifier: cellId)
        self.dataSource = self
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? Cell
            else { fatalError("Could not dequeue Cell") }
        cell.set(data: data[indexPath.row])
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        manequinCell.set(data: data[indexPath.row])
        let finalMaxSize = CGSize(
            width: maxSize.width == 0 ? collectionView.bounds.width : maxSize.width,
            height: maxSize.height
        )
        let size = manequinCell.clip.measureSize(within: finalMaxSize)
        manequinCell.clip.invalidateCache()
        return size
    }
}

open class ClipCell: UICollectionViewCell {
    override open func layoutSubviews() {
        super.layoutSubviews()
        clip.layoutSubviews()
    }
}
