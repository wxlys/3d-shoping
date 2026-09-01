<template>
  <div class="print-inquiry-page">
    <el-card :bordered="false" shadow="never" class="ivu-mt" :body-style="{ padding: 0 }">
      <div class="padding-add">
        <el-form :model="query" inline @submit.native.prevent>
          <el-form-item label="状态：">
            <el-select v-model="query.status" clearable placeholder="全部状态" style="width: 130px">
              <el-option :value="1" label="待报价" />
              <el-option :value="2" label="已报价" />
              <el-option :value="3" label="已确认" />
              <el-option :value="4" label="已过期" />
              <el-option :value="5" label="已取消" />
            </el-select>
          </el-form-item>
          <el-form-item label="搜索：">
            <el-input v-model="query.keyword" clearable placeholder="询价单号或文件名" @keyup.enter.native="search" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" v-db-click @click="search">查询</el-button>
            <el-button v-db-click @click="reset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>
    </el-card>

    <el-card :bordered="false" shadow="never" class="ivu-mt">
      <el-table :data="list" v-loading="loading" highlight-current-row>
        <el-table-column label="询价单号" min-width="175" prop="inquiry_no" />
        <el-table-column label="用户" min-width="145">
          <template slot-scope="scope">{{ scope.row.user.nickname || scope.row.uid }}（{{ scope.row.uid }}）</template>
        </el-table-column>
        <el-table-column label="模型文件" min-width="175" show-overflow-tooltip>
          <template slot-scope="scope">{{ scope.row.file.filename || '-' }}</template>
        </el-table-column>
        <el-table-column label="规格" min-width="125">
          <template slot-scope="scope">{{ scope.row.size_level }} / {{ scope.row.material }} × {{ scope.row.quantity }}</template>
        </el-table-column>
        <el-table-column label="报价" width="110">
          <template slot-scope="scope">{{ scope.row.quote_amount > 0 ? `¥ ${scope.row.quote_amount}` : '-' }}</template>
        </el-table-column>
        <el-table-column label="预计交付" min-width="160" prop="quote_expected_deliver_at_text" />
        <el-table-column label="提交时间" min-width="160" prop="add_time_text" />
        <el-table-column label="有效期至" min-width="160" prop="expire_at_text" />
        <el-table-column label="状态" width="100">
          <template slot-scope="scope">
            <el-tag size="mini" :type="statusTag(scope.row.status)">{{ scope.row.status_name }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" fixed="right" width="200">
          <template slot-scope="scope">
            <el-button type="text" v-db-click @click="openInfo(scope.row)">详情</el-button>
            <el-button v-if="scope.row.status === 1" type="text" v-db-click @click="openQuote(scope.row)">报价</el-button>
            <el-button v-if="scope.row.status === 2" type="text" v-db-click @click="expire(scope.row)">作废报价</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="acea-row row-right page">
        <pagination v-if="total" :total="total" :page.sync="query.page" :limit.sync="query.limit" @pagination="getList" />
      </div>
    </el-card>

    <el-dialog :visible.sync="infoVisible" title="询价单详情" width="620px">
      <el-descriptions v-if="detail" :column="2" border size="small">
        <el-descriptions-item label="询价单号">{{ detail.inquiry_no }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ detail.status_name }}</el-descriptions-item>
        <el-descriptions-item label="用户">{{ detail.user.nickname || '-' }}（{{ detail.uid }}）</el-descriptions-item>
        <el-descriptions-item label="联系电话">{{ detail.user.phone || '-' }}</el-descriptions-item>
        <el-descriptions-item label="模型文件">{{ detail.file.filename || '-' }}</el-descriptions-item>
        <el-descriptions-item label="文件大小">{{ detail.file.size_text || '-' }}</el-descriptions-item>
        <el-descriptions-item label="尺寸 / 材料">{{ detail.size_level }} / {{ detail.material }}</el-descriptions-item>
        <el-descriptions-item label="数量">{{ detail.quantity }}</el-descriptions-item>
        <el-descriptions-item label="报价">{{ detail.quote_amount > 0 ? `¥ ${detail.quote_amount}` : '-' }}</el-descriptions-item>
        <el-descriptions-item label="预计交付">{{ detail.quote_expected_deliver_at_text || '-' }}</el-descriptions-item>
        <el-descriptions-item label="有效期至">{{ detail.expire_at_text || '-' }}</el-descriptions-item>
        <el-descriptions-item label="模型操作" :span="2">
          <a v-if="detail.file.file_url" :href="detail.file.file_url" target="_blank">打开 / 下载模型</a>
          <span v-else>暂无地址</span>
        </el-descriptions-item>
        <el-descriptions-item v-if="detail.order.order_id" label="订单号" :span="2">{{ detail.order.order_id }}</el-descriptions-item>
      </el-descriptions>
      <div slot="footer">
        <el-button @click="infoVisible = false">关闭</el-button>
      </div>
    </el-dialog>

    <el-dialog :visible.sync="quoteVisible" title="填写报价" width="450px">
      <el-form label-width="100px" @submit.native.prevent>
        <el-form-item label="询价单号：">{{ currentRow.inquiry_no }}</el-form-item>
        <el-form-item label="模型规格：">{{ currentRow.size_level }} / {{ currentRow.material }} × {{ currentRow.quantity }}</el-form-item>
        <el-form-item label="报价金额：">
          <el-input v-model="quoteForm.quote_amount" type="number" min="0.01" step="0.01" placeholder="请输入报价金额">
            <span slot="prepend">¥</span>
          </el-input>
        </el-form-item>
        <el-form-item label="预计交付：">
          <el-date-picker
            v-model="quoteForm.quote_expected_deliver_at"
            type="datetime"
            value-format="timestamp"
            format="yyyy-MM-dd HH:mm"
            :picker-options="quotePickerOptions"
            placeholder="请选择预计交付时间"
            style="width: 250px"
          />
        </el-form-item>
        <div class="quote-tip">报价默认有效期 {{ expireHours }} 小时，预计交付时间须晚于当前时间。</div>
      </el-form>
      <div slot="footer">
        <el-button @click="quoteVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" v-db-click @click="saveQuote">提交报价</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { printInquiryExpire, printInquiryInfo, printInquiryList, printInquiryQuote } from '@/api/print';

export default {
  name: 'PrintInquiry',
  data() {
    return {
      loading: false,
      saving: false,
      total: 0,
      list: [],
      detail: null,
      query: { page: 1, limit: 20, status: '', keyword: '' },
      currentRow: {},
      quoteForm: { quote_amount: '', quote_expected_deliver_at: '' },
      quoteVisible: false,
      infoVisible: false,
      expireHours: 48,
      quotePickerOptions: {
        disabledDate: (date) => date.getTime() <= Date.now(),
      },
    };
  },
  created() {
    this.getList();
  },
  methods: {
    getList() {
      this.loading = true;
      printInquiryList(this.query)
        .then((res) => {
          const data = res.data || {};
          this.list = data.list || [];
          this.total = Number(data.count || 0);
        })
        .catch((err) => this.$message.error(err.msg || err.message || '询价列表加载失败'))
        .finally(() => {
          this.loading = false;
        });
    },
    search() {
      this.query.page = 1;
      this.getList();
    },
    reset() {
      this.query.status = '';
      this.query.keyword = '';
      this.search();
    },
    statusTag(status) {
      return { 1: 'warning', 2: '', 3: 'success', 4: 'info', 5: 'info' }[status] || 'info';
    },
    openInfo(row) {
      printInquiryInfo(row.id)
        .then((res) => {
          this.detail = res.data;
          this.infoVisible = true;
        })
        .catch((err) => this.$message.error(err.msg || err.message || '详情加载失败'));
    },
    openQuote(row) {
      this.currentRow = row;
      this.quoteForm.quote_amount = '';
      this.quoteForm.quote_expected_deliver_at = '';
      this.quoteVisible = true;
    },
    saveQuote() {
      if (!this.quoteForm.quote_amount || Number(this.quoteForm.quote_amount) <= 0) {
        this.$message.warning('请输入大于0的报价');
        return;
      }
      if (!this.quoteForm.quote_expected_deliver_at || Number(this.quoteForm.quote_expected_deliver_at) <= Date.now()) {
        this.$message.warning('请选择晚于当前时间的预计交付时间');
        return;
      }
      this.saving = true;
      printInquiryQuote(this.currentRow.id, {
        quote_amount: this.quoteForm.quote_amount,
        quote_expected_deliver_at: this.quoteForm.quote_expected_deliver_at,
      })
        .then(() => {
          this.$message.success('报价已保存');
          this.quoteVisible = false;
          this.getList();
        })
        .catch((err) => this.$message.error(err.msg || err.message || '报价保存失败'))
        .finally(() => {
          this.saving = false;
        });
    },
    expire(row) {
      this.$confirm(`确认作废询价单 ${row.inquiry_no} 的报价吗？`, '提示', { type: 'warning' })
        .then(() => printInquiryExpire(row.id))
        .then(() => {
          this.$message.success('报价已作废');
          this.getList();
        })
        .catch((err) => {
          if (err !== 'cancel' && err !== 'close') this.$message.error(err.msg || err.message || '操作失败');
        });
    },
  },
};
</script>

<style lang="scss" scoped>
.page {
  padding-top: 16px;
}

.quote-tip {
  color: #909399;
  padding-left: 100px;
  font-size: 12px;
}
</style>
