'use strict';

const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
  entry: './src/app.js',

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js',
    clean: true,
  },

  module: {
    rules: [
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(woff|woff2|eot|ttf|svg)$/,
        type: 'asset/resource',
        generator: {
          filename: 'fonts/[name][ext]',
        },
      },
    ],
  },

  plugins: [
    new HtmlWebpackPlugin({
      template: './src/index.html',
      filename: 'index.html',
    }),
    new CopyWebpackPlugin({
      patterns: [
        {
          from: path.resolve(__dirname, 'diagrams'),
          to: path.resolve(__dirname, 'dist/diagrams'),
        },
      ],
    }),
  ],

  devServer: {
    port: 9013,
    host: 'localhost',
    open: true,
    hot: true,
    static: {
      directory: path.resolve(__dirname, 'dist'),
    },
  },

  resolve: {
    extensions: ['.js'],
  },

  mode: 'development',
  devtool: 'source-map',
};
