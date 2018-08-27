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

open class ClipCollectionView<Cell: DataBinder, Header: DataBinder, Footer: DataBinder>:
    UICollectionView,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
    where
    Cell: ClipCell,
    Header: ClipCell,
    Footer: ClipCell
{
    public var footerEnabled = true
    public var headerEnabled = true
    
    public var cellData: [[Cell.Data]] = []
    public var headerData: [Header.Data] = []
    public var footerData: [Footer.Data] = []
    
    public var maxCellSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
    public var maxHeaderSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
    public var maxFooterSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
    
    private let cellId = "cellId"
    private let headerId = "headerId"
    private let footerId = "footerId"
    
    private let manequinCell = Cell()
    private let manequinHeader = Header()
    private let manequinFooter = Footer()
    
    public init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
        register(Cell.self, forCellWithReuseIdentifier: cellId)
        register(Header.self,
                 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                 withReuseIdentifier: headerId)
        register(Footer.self,
                 forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                 withReuseIdentifier: footerId)
        self.dataSource = self
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return cellData.count
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
        return cellData[section].count
    }
    
    //MARK: - CELLS
    open func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId,
                                                         for: indexPath) as? Cell {
            cell.set(data: cellData[indexPath.section][indexPath.row])
            return cell
        }
        
        fatalError("Could not dequeue reusable cell")
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        manequinCell.set(data: cellData[indexPath.section][indexPath.row])
        
        let finalMaxSize = CGSize(
            width: maxCellSize.width == 0 ? collectionView.bounds.width : maxCellSize.width,
            height: maxCellSize.height
        )
        
        let size = manequinCell.clip.measureSize(within: finalMaxSize)
        manequinCell.clip.invalidateCache()
        return size
    }
    
    //MARK: - HEADER & FOOTER
    open func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        guard headerEnabled else { return .zero }
        manequinHeader.set(data: headerData[section])
        
        var finalMaxSize = CGSize(
            width: maxHeaderSize.width == 0 ? collectionView.bounds.width : maxHeaderSize.width,
            height: maxHeaderSize.height
        )
        adjustForScrollDirection(size: &finalMaxSize, for: collectionViewLayout, in: collectionView)
        let size = manequinHeader.clip.measureSize(within: finalMaxSize)
        manequinHeader.clip.invalidateCache()
        return size
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             referenceSizeForFooterInSection section: Int) -> CGSize {
        
        guard footerEnabled else { return .zero }
        manequinFooter.set(data: footerData[section])
        
        var finalMaxSize = CGSize(
            width: maxFooterSize.width == 0 ? collectionView.bounds.width : maxFooterSize.width,
            height: maxFooterSize.height
        )
        adjustForScrollDirection(size: &finalMaxSize, for: collectionViewLayout, in: collectionView)
        let size = manequinFooter.clip.measureSize(within: finalMaxSize)
        manequinFooter.clip.invalidateCache()
        return size
    }
    
    open func collectionView(_ collectionView: UICollectionView,
                             viewForSupplementaryElementOfKind kind: String,
                             at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: headerId,
                                                                         for: indexPath) as? Header {
            return header
        }
        
        if let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                        withReuseIdentifier: footerId,
                                                                        for: indexPath) as? Footer {
            return footer
        }
        
        fatalError("Could not dequeue reusable supplementary view")
    }
    
    //MARK: - PRIVATE
    private func adjustForScrollDirection(size: inout CGSize,
                                          for collectionViewLayout: UICollectionViewLayout,
                                          in collectionView: UICollectionView) {
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            if layout.scrollDirection == .vertical {
                size.width = collectionView.bounds.width
            }
            else if layout.scrollDirection == .horizontal {
                size.height = collectionView.bounds.height
            }
        }
    }
}

open class ClipCell: UICollectionViewCell {
    override open func layoutSubviews() {
        super.layoutSubviews()
        clip.layoutSubviews()
    }
}
