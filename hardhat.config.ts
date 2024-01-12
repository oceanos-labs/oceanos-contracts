import * as dotenv from "dotenv";
dotenv.config();

import "@nomicfoundation/hardhat-network-helpers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "./tasks";
import { ethers } from "ethers";
import "hardhat-gas-reporter";
const { PRIVATE_KEY } = process.env;

const PVT =
    PRIVATE_KEY ||
    "0x103e6c2538e1d15593be3bdc1b7a4a44e2112df866c9054238eca65f829df763" ||
    ethers.Wallet.createRandom().privateKey;

const config = {
    solidity: {
        compilers: [
            {
                version: "0.8.17",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        hardhat: {
            forking: {
                url: "https://pacific-rpc.manta.network/http",
                blockNumber: 580293,
            },
            accounts: [
                {
                    privateKey: PVT,
                    balance: "1000000000000000000000000000",
                },
            ],
            saveDeployments: false,
            tags: ["test", "local"],
        },

        manta: {
            chainId: 169,
            url: "https://pacific-rpc.manta.network/http",
            accounts: [PVT!],
            verify: {
                etherscan: {
                    apiUrl: "https://manta-pacific.calderaexplorer.xyz/api",
                    apiKey: "asd"!,
                },
            },
        },
        manta_test: {
            chainId: 3441005,
            url: "https://pacific-info.testnet.manta.network/",
            accounts: [PVT!],
            verify: {
                etherscan: {
                    apiUrl: "",
                    apiKey: process.env.WEMIX_SCAN_API_KEY!,
                },
            },
            gasPrice: 1000000000,
        },
        wemix_test: {
            chainId: 1112,
            url: "https://api.test.wemix.com/",
            accounts: [PVT!],
            verify: {
                etherscan: {
                    apiUrl: "https://api-testnet.wemixscan.com",
                    apiKey: process.env.WEMIX_SCAN_API_KEY!,
                },
            },
            gasPrice: 100e9 + 1,
            gasLimit: 800000000,
        },
        klaytn: {
            chainId: 8217,
            url: "https://klaytn.blockpi.network/v1/rpc/public",
            accounts: [PVT!],
        },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    gasReporter: {
        currency: "USD",
        gasPrice: 100,
        enabled: true,
    },

    // files
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
};

export default config;
