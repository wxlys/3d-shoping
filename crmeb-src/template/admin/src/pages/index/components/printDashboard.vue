<template>
  <div class="print-dashboard" v-loading="loading">
    <el-row :gutter="16" class="ivu-mb">
      <el-col v-for="item in headlineCards" :key="item.key" :xl="6" :lg="6" :md="12" :sm="12" :xs="24">
        <el-card shadow="never" class="metric-card">
          <div class="metric-title">{{ item.title }}</div>
          <div class="metric-value">{{ item.value }}</div>
          <div class="metric-note">{{ item.note }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="ivu-mb">
      <el-col :xl="12" :lg="12" :md="24" :sm="24" :xs="24">
        <el-card shadow="never">
          <div slot="header">打印订单状态</div>
          <el-row :gutter="12" class="status-grid">
            <el-col v-for="item in printStatusCards" :key="item.key" :span="8">
              <div class="status-item">
                <span>{{ item.title }}</span>
                <strong>{{ item.value }}</strong>
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-col>
      <el-col :xl="12" :lg="12" :md="24" :sm="24" :xs="24">
        <el-card shadow="never">
          <div slot="header">待处理提醒</div>
          <el-row :gutter="12" class="status-grid">
            <el-col v-for="item in alertCards" :key="item.key" :span="12">
              <div class="status-item">
                <span>{{ item.title }}</span>
                <strong>{{ item.value }}</strong>
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never">
      <div slot="header">近 7 天销售额与订单量</div>
      <el-table :data="last7" size="small" stripe>
        <el-table-column prop="date" label="日期" width="140" />
        <el-table-column prop="orders" label="已支付订单量" />
        <el-table-column label="销售额">
          <template slot-scope="scope">¥ {{ Number(scope.row.sales || 0).toFixed(2) }}</template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { printStatsApi } from '@/api/index';

export default {
  name: 'print-dashboard',
  data() {
    return {
      loading: false,
      stats: {
        today: {},
        last7: [],
        orders: {},
        print: {},
        inquiry: {},
        alerts: {},
      },
    };
  },
  computed: {
    headlineCards() {
      return [
        { key: 'sales', title: '今日成交额', value: `¥ ${Number(this.stats.today.sales || 0).toFixed(2)}`, note: '仅统计已支付且未退款订单' },
        { key: 'orders', title: '今日订单', value: this.stats.today.orders || 0, note: '今日已支付订单' },
        { key: 'inquiry', title: '待报价询价', value: this.stats.inquiry.pending_quote || 0, note: '需要客服或报价人员处理' },
        { key: 'queue', title: '打印队列', value: (this.stats.print.queue || 0) + (this.stats.print.printing || 0), note: `排队 ${this.stats.print.queue || 0} · 制作 ${this.stats.print.printing || 0}` },
      ];
    },
    printStatusCards() {
      return [
        { key: 'queue', title: '排队中', value: this.stats.print.queue || 0 },
        { key: 'printing', title: '制作中', value: this.stats.print.printing || 0 },
        { key: 'pickup', title: '待取件', value: this.stats.print.ready_pickup || 0 },
        { key: 'ship', title: '普通待发货', value: this.stats.orders.pending_ship || 0 },
        { key: 'receive', title: '普通待收货', value: this.stats.orders.pending_receive || 0 },
        { key: 'evaluate', title: '待评价', value: this.stats.orders.pending_evaluation || 0 },
      ];
    },
    alertCards() {
      return [
        { key: 'quote', title: '已报价待确认', value: this.stats.inquiry.quoted || 0 },
        { key: 'refund', title: '退款待处理', value: this.stats.alerts.refund_pending || 0 },
        { key: 'stock', title: '库存预警', value: this.stats.alerts.inventory_warning || 0 },
        { key: 'payment', title: '待支付订单', value: this.stats.orders.pending_payment || 0 },
      ];
    },
    last7() {
      return this.stats.last7 || [];
    },
  },
  created() {
    this.loadStats();
  },
  methods: {
    loadStats() {
      this.loading = true;
      printStatsApi()
        .then((res) => {
          this.stats = Object.assign(this.stats, res.data || {});
        })
        .catch((res) => {
          this.$message.error(res.msg || '打印业务统计加载失败');
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<style lang="scss" scoped>
.print-dashboard {
  margin-top: 16px;
}
.ivu-mb {
  margin-bottom: 16px;
}
.metric-card {
  min-height: 132px;
}
.metric-title {
  color: #86909c;
  font-size: 14px;
}
.metric-value {
  margin-top: 12px;
  color: #1d2129;
  font-size: 28px;
  line-height: 38px;
}
.metric-note {
  color: #86909c;
  font-size: 12px;
}
.status-grid {
  margin: -4px;
}
.status-item {
  display: flex;
  justify-content: space-between;
  margin: 4px;
  padding: 12px;
  background: #f7f8fa;
  color: #4e5969;
}
.status-item strong {
  color: #1d2129;
  font-size: 18px;
}
</style>
