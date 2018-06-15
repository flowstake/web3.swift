//
//  EthereumTransaction.swift
//  web3swift
//
//  Created by Julien Niset on 23/02/2018.
//  Copyright © 2018 Argent Labs Limited. All rights reserved.
//

import Foundation
import BigInt

protocol EthereumTransactionProtocol {
    init(from: String?, to: String, value: BigUInt?, data: Data?, nonce: Int?, gasPrice: BigUInt?, gasLimit: BigUInt?, chainId: Int?)
    init(from: String?, to: String, data: Data, gasPrice: BigUInt, gasLimit: BigUInt)
    init(to: String, data: Data)
    
    var raw: Data? { get }
    var hash: Data? { get }
}

public struct EthereumTransaction: EthereumTransactionProtocol, Codable {
    public let from: String?
    public let to: String
    public let value: BigUInt?
    public let data: Data?
    public var nonce: Int?
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public let gas: BigUInt?
    var chainId: Int?
    
    public init(from: String?, to: String, value: BigUInt?, data: Data?, nonce: Int?, gasPrice: BigUInt?, gasLimit: BigUInt?, chainId: Int?) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data ?? Data()
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.chainId = chainId
        self.gas = nil
    }
    
    public init(from: String?, to: String, data: Data, gasPrice: BigUInt, gasLimit: BigUInt) {
        self.from = from
        self.to = to
        self.value = BigUInt(0)
        self.data = data
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.gas = nil
    }
    
    public init(to: String, data: Data) {
        self.from = nil
        self.to = to
        self.value = BigUInt(0)
        self.data = data
        self.gasPrice = BigUInt(0)
        self.gasLimit = BigUInt(0)
        self.gas = nil
    }
    
    var raw: Data? {
        let txArray: [Any?] = [self.nonce, self.gasPrice, self.gasLimit, self.to.noHexPrefix, self.value, self.data, self.chainId, 0, 0]

        return RLP.encode(txArray)
    }
    
    var hash: Data? {
        return raw?.keccak256
    }
    
    enum CodingKeys : String, CodingKey {
        case from
        case to
        case value
        case data
        case nonce
        case gasPrice
        case gas
        case gasLimit
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.to = try container.decode(String.self, forKey: .to)
        self.from = try? container.decode(String.self, forKey: .from)
        self.data = try? container.decode(Data.self, forKey: .data)
        
        let decodeHexUInt = { (key: CodingKeys) -> BigUInt? in
            return (try? container.decode(String.self, forKey: key)).flatMap { BigUInt(hex: $0)}
        }
        
        let decodeHexInt = { (key: CodingKeys) -> Int? in
            return (try? container.decode(String.self, forKey: key)).flatMap { Int(hex: $0)}
        }
        
        self.value = decodeHexUInt(.value)
        self.gasLimit = decodeHexUInt(.gasLimit)
        self.gasPrice = decodeHexUInt(.gasPrice)
        self.gas = decodeHexUInt(.gas)
        self.nonce = decodeHexInt(.nonce)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(to, forKey: .to)
        try? container.encode(from, forKey: .from)
        try? container.encode(data, forKey: .data)
        try? container.encode(value?.hexString, forKey: .value)
        try? container.encode(gasPrice?.hexString, forKey: .gasPrice)
        try? container.encode(gasLimit?.hexString, forKey: .gasLimit)
        try? container.encode(gas?.hexString, forKey: .gas)
        try? container.encode(nonce?.hexString, forKey: .nonce)
    }
}

struct SignedTransaction {
    let transaction: EthereumTransaction
    let v: Int
    let r: Data
    let s: Data
    
    init(transaction: EthereumTransaction, v: Int, r: Data, s: Data) {
        self.transaction = transaction
        self.v = v
        self.r = r.strippingZeroesFromBytes
        self.s = s.strippingZeroesFromBytes
    }
    
    var raw: Data? {
        let txArray: [Any?] = [transaction.nonce, transaction.gasPrice, transaction.gasLimit, transaction.to.noHexPrefix, transaction.value, transaction.data, self.v, self.r, self.s]

        return RLP.encode(txArray)
    }
    
    var hash: Data? {
        return raw?.keccak256
    }
}
