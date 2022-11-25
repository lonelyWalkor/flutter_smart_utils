const testPrintJson = [
  {
    'method': 'text',
    'text': '#46 测试平台',
    'font': 2,
    'align': 'center',
    'bold': true
  },
  {
    'method': 'text',
    'text': '测试页店铺名称',
    'font': 2,
    'align': 'center',
    'bold': true
  },
  {
    'method': 'text',
    'text': '备注：{备注}',
    'font': 2,
    'align': 'left',
    'bold': true
  },
  {
    'method': 'hr',
  },
  {
    'method': 'feed',
    'line': 1,
  },
  {
    'method': 'hr',
  },
  {
    'method': 'text',
    'text': '订单编号：{订单编号}',
    'font': 1,
    'align': 'left',
    'bold': true
  },
  {
    'method': 'text',
    'text': '下单时间：{下单时间}',
    'font': 1,
    'align': 'left',
    'bold': true
  },
  {
    'method': 'hr',
  },
  {
    'method': 'text',
    'text': '1号口袋',
    'font': 1,
    'align': 'center',
    'bold': true
  },
  {
    'method': 'row',
    'rows': [
      {
        'width': 6,
        'method': 'text',
        'text': '商品',
        'font': 1,
        'align': 'left',
        'bold': false
      },
      {
        'width': 3,
        'method': 'text',
        'text': '数量',
        'font': 1,
        'align': 'right',
        'bold': false
      },
      {
        'width': 3,
        'method': 'text',
        'text': '价格',
        'font': 1,
        'align': 'right',
        'bold': false
      },
    ],
  },
  {
    'method': 'row',
    'rows': [
      {
        'width': 6,
        'method': 'text',
        'text': '商品名称',
        'font': 1,
        'align': 'left',
        'bold': false
      },
      {
        'width': 3,
        'method': 'text',
        'text': '商品数量',
        'font': 1,
        'align': 'right',
        'bold': false
      },
      {
        'width': 3,
        'method': 'text',
        'text': '商品价格',
        'font': 1,
        'align': 'right',
        'bold': false
      },
    ],
  },
  {
    'method': 'text',
    'text': '（商品规格属性，规格属性）',
    'font': 1,
    'align': 'left',
    'bold': false
  },
  {
    'method': 'row',
    'rows': [
      {
        'width': 6,
        'method': 'text',
        'text': '商品名称',
        'font': 1,
        'align': 'left',
        'bold': false
      },
      {
        'width': 3,
        'method': 'text',
        'text': '商品数量',
        'font': 1,
        'align': 'right',
        'bold': false
      },
      {
        'width': 3,
        'method': 'text',
        'text': '商品价格',
        'font': 1,
        'align': 'right',
        'bold': false
      },
    ],
  },
  {
    'method': 'hr',
  },
  {
    'method': 'text',
    'text': '门店新客立减 2.5',
    'font': 1,
    'align': 'left',
    'bold': true
  },
  {
    'method': 'text',
    'text': '总计 2.5',
    'font': 1,
    'align': 'left',
    'bold': true
  },
  {
    'method': 'hr',
  },
  {
    'method': 'text',
    'text': '地址:这是一个测试地址',
    'font': 2,
    'align': 'left',
    'bold': false
  },
  {
    'method': 'text',
    'text': '名字:这是一个测试地址',
    'font': 2,
    'align': 'left',
    'bold': false
  },
  {
    'method': 'text',
    'text': '电话:1111111111',
    'font': 2,
    'align': 'left',
    'bold': false
  },
  {
    'method': 'text',
    'text': '** 46 完 **',
    'font': 2,
    'align': 'center',
    'bold': false
  },
  {
    'method': 'qrcode',
    'text': 'test qrcode',
    'align': 'center',
    'size': 8,
  },
  {
    'method': 'barcode',
    'data': [1,4,6,8,0, 9, 9 ,9, 7 , 7, 8],
  },
  {
    'method': 'feed',
    'line': 1,
  },
  {
    'method': 'cut',
  },
];