// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

library LidoAddressBook {
  // Ethereum
  address internal constant TRANSPARENT_PROXY_FACTORY_ETHEREUM = address(0);
  address internal constant TRANSPARENT_PROXY_FACTORY_ETHEREUM_TESTNET = 0x3BfEF10368F09dC4E7d1969AD9eF78ea783D6134;

  address internal constant PROXY_ADMIN_ETHEREUM = address(0);
  address internal constant PROXY_ADMIN_ETHEREUM_TESTNET = 0x170998d7674c0E1c2Cd1d62185FC634A8046Deea;

  // Polygon
  address internal constant TRANSPARENT_PROXY_FACTORY_POLYGON = address(0);
  address internal constant TRANSPARENT_PROXY_FACTORY_POLYGON_TESTNET = address(0);

  address internal constant PROXY_ADMIN_POLYGON = address(0);
  address internal constant PROXY_ADMIN_POLYGON_TESTNET = address(0);

  // Binance
  address internal constant TRANSPARENT_PROXY_FACTORY_BINANCE = address(0);
  address internal constant TRANSPARENT_PROXY_FACTORY_BINANCE_TESTNET = 0x3Daa222feD0649357eDE1777BCB7BcF9D74328E4;

  address internal constant PROXY_ADMIN_BINANCE = address(0);
  address internal constant PROXY_ADMIN_BINANCE_TESTNET = 0x8f5245141E30543E51B44c0b5D7E88e1bf92DEF5;
}
